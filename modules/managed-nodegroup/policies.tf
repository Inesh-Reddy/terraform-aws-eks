resource "kubectl_manifest" "add_network_policy" {
  yaml_body = <<-YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: add-networkpolicy
    annotations:
      policies.kyverno.io/title: Add Network Policy
      policies.kyverno.io/category: Multi-Tenancy
      policies.kyverno.io/subject: NetworkPolicy
      policies.kyverno.io/description: >-
        By default, Kubernetes allows communications across all Pods within a cluster.
        The NetworkPolicy resource and a CNI plug-in that supports NetworkPolicy must be used to restrict
        communications. A default NetworkPolicy should be configured for each Namespace to
        default deny all ingress and egress traffic to the Pods in the Namespace. Application
        teams can then configure additional NetworkPolicy resources to allow desired traffic
        to application Pods from select sources. This policy will create a new NetworkPolicy resource
        named `default-deny` which will deny all traffic anytime a new Namespace is created.      
  spec:
    rules:
    - name: default-deny
      match:
        any:
        - resources:
            kinds:
            - Namespace
      generate:
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        name: default-deny
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        data:
          spec:
            podSelector: {}
            policyTypes:
            - Ingress
            - Egress
  YAML

  depends_on = [
    helm_release.kyverno
  ]
}

resource "kubectl_manifest" "disallow_default_namespace" {
  yaml_body = <<-YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: disallow-default-namespace
    annotations:
      pod-policies.kyverno.io/autogen-controllers: none
      policies.kyverno.io/title: Disallow Default Namespace
      policies.kyverno.io/category: Multi-Tenancy
      policies.kyverno.io/severity: medium
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: >-
        Kubernetes Namespaces are an optional feature that provide a way to segment and
        isolate cluster resources across multiple applications and users. As a best
        practice, workloads should be isolated with Namespaces. Namespaces should be required
        and the default (empty) Namespace should not be used. This policy validates that Pods
        specify a Namespace name other than `default`.      
  spec:
    validationFailureAction: enforce
    background: true
    rules:
    - name: validate-namespace
      match:
        resources:
          kinds:
          - Pod
      validate:
        message: "Using 'default' namespace is not allowed."
        pattern:
          metadata:
            namespace: "!default"
    - name: validate-podcontroller-namespace
      match:
        resources:
          kinds:
          - DaemonSet
          - Deployment
          - Job
          - StatefulSet
      validate:
        message: "Using 'default' namespace is not allowed for pod controllers."
        pattern:
          metadata:
            namespace: "!default"
  YAML

  depends_on = [
    helm_release.kyverno
  ]
}

resource "kubectl_manifest" "require-run-as-nonroot" {

  yaml_body = <<-YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: require-run-as-nonroot
    annotations:
      policies.kyverno.io/title: Require runAsNonRoot
      policies.kyverno.io/category: Pod Security Standards (Restricted)
      policies.kyverno.io/severity: medium
      policies.kyverno.io/subject: Pod
      kyverno.io/kyverno-version: 1.6.0
      kyverno.io/kubernetes-version: "1.22-1.23"
      policies.kyverno.io/description: >-
        Containers must be required to run as non-root users. This policy ensures
        `runAsNonRoot` is set to `true`. A known issue prevents a policy such as this
        using `anyPattern` from being persisted properly in Kubernetes 1.23.0-1.23.2.
  spec:
    validationFailureAction: audit
    background: true
    rules:
      - name: run-as-non-root
        match:
          any:
          - resources:
              kinds:
                - Pod
        validate:
          message: >-
            Running as root is not allowed. Either the field spec.securityContext.runAsNonRoot
            must be set to `true`, or the fields spec.containers[*].securityContext.runAsNonRoot,
            spec.initContainers[*].securityContext.runAsNonRoot, and spec.ephemeralContainers[*].securityContext.runAsNonRoot
            must be set to `true`.
          anyPattern:
          - spec:
              securityContext:
                runAsNonRoot: "true"
              =(ephemeralContainers):
              - =(securityContext):
                  =(runAsNonRoot): "true"
              =(initContainers):
              - =(securityContext):
                  =(runAsNonRoot): "true"
              containers:
              - =(securityContext):
                  =(runAsNonRoot): "true"
          - spec:
              =(ephemeralContainers):
              - securityContext:
                  runAsNonRoot: "true"
              =(initContainers):
              - securityContext:
                  runAsNonRoot: "true"
              containers:
              - securityContext:
                  runAsNonRoot: "true"
  YAML
  depends_on = [
    helm_release.kyverno
  ]
}

resource "kubectl_manifest" "disallow-capabilities-strict" {

  yaml_body = <<-YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: disallow-capabilities-strict
    annotations:
      policies.kyverno.io/title: Disallow Capabilities (Strict)
      policies.kyverno.io/category: Pod Security Standards (Restricted)
      policies.kyverno.io/severity: medium
      policies.kyverno.io/minversion: 1.6.0
      kyverno.io/kyverno-version: 1.6.0
      kyverno.io/kubernetes-version: "1.22-1.23"
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: >-
        Adding capabilities other than `NET_BIND_SERVICE` is disallowed. In addition,
        all containers must explicitly drop `ALL` capabilities.
  spec:
    validationFailureAction: audit
    background: true
    rules:
      - name: require-drop-all
        match:
          any:
          - resources:
              kinds:
                - Pod
        preconditions:
          all:
          - key: "{{ request.operation }}"
            operator: NotEquals
            value: DELETE
        validate:
          message: >-
            Containers must drop `ALL` capabilities.
          foreach:
            - list: request.object.spec.[ephemeralContainers, initContainers, containers][]
              deny:
                conditions:
                  all:
                  - key: ALL
                    operator: AnyNotIn
                    value: "{{ element.securityContext.capabilities.drop || '' }}"
      - name: adding-capabilities-strict
        match:
          any:
          - resources:
              kinds:
                - Pod
        preconditions:
          all:
          - key: "{{ request.operation }}"
            operator: NotEquals
            value: DELETE
        validate:
          message: >-
            Any capabilities added other than NET_BIND_SERVICE are disallowed.
          foreach:
            - list: request.object.spec.[ephemeralContainers, initContainers, containers][]
              deny:
                conditions:
                  all:
                  - key: "{{ element.securityContext.capabilities.add[] || '' }}"
                    operator: AnyNotIn
                    value:
                    - NET_BIND_SERVICE
                    - ''
  YAML
  depends_on = [
    helm_release.kyverno
  ]
}


resource "kubectl_manifest" "disallow-privilege-escalation" {

  yaml_body = <<-YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: disallow-privilege-escalation
    annotations:
      policies.kyverno.io/title: Disallow Privilege Escalation
      policies.kyverno.io/category: Pod Security Standards (Restricted)
      policies.kyverno.io/severity: medium
      policies.kyverno.io/subject: Pod
      kyverno.io/kyverno-version: 1.6.0
      kyverno.io/kubernetes-version: "1.22-1.23"
      policies.kyverno.io/description: >-
        Privilege escalation, such as via set-user-ID or set-group-ID file mode, should not be allowed.
        This policy ensures the `allowPrivilegeEscalation` field is set to `false`.
  spec:
    validationFailureAction: audit
    background: true
    rules:
      - name: privilege-escalation
        match:
          any:
          - resources:
              kinds:
                - Pod
        validate:
          message: >-
            Privilege escalation is disallowed. The fields
            spec.containers[*].securityContext.allowPrivilegeEscalation,
            spec.initContainers[*].securityContext.allowPrivilegeEscalation,
            and spec.ephemeralContainers[*].securityContext.allowPrivilegeEscalation
            must be set to `false`.
          pattern:
            spec:
              =(ephemeralContainers):
              - securityContext:
                  allowPrivilegeEscalation: "false"
              =(initContainers):
              - securityContext:
                  allowPrivilegeEscalation: "false"
              containers:
              - securityContext:
                  allowPrivilegeEscalation: "false"
  YAML
  depends_on = [
    helm_release.kyverno
  ]
}

resource "kubectl_manifest" "require-run-as-non-root-user" {

  yaml_body = <<-YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: require-run-as-non-root-user
    annotations:
      policies.kyverno.io/title: Require Run As Non-Root User
      policies.kyverno.io/category: Pod Security Standards (Restricted)
      policies.kyverno.io/severity: medium
      policies.kyverno.io/subject: Pod
      kyverno.io/kyverno-version: 1.6.0
      kyverno.io/kubernetes-version: "1.22-1.23"
      policies.kyverno.io/description: >-
        Containers must be required to run as non-root users. This policy ensures
        `runAsUser` is either unset or set to a number greater than zero.
  spec:
    validationFailureAction: audit
    background: true
    rules:
      - name: run-as-non-root-user
        match:
          any:
          - resources:
              kinds:
                - Pod
        validate:
          message: >-
            Running as root is not allowed. The fields spec.securityContext.runAsUser,
            spec.containers[*].securityContext.runAsUser, spec.initContainers[*].securityContext.runAsUser,
            and spec.ephemeralContainers[*].securityContext.runAsUser must be unset or
            set to a number greater than zero.
          pattern:
            spec:
              =(securityContext):
                =(runAsUser): ">0"
              =(ephemeralContainers):
              - =(securityContext):
                  =(runAsUser): ">0"
              =(initContainers):
              - =(securityContext):
                  =(runAsUser): ">0"
              containers:
              - =(securityContext):
                  =(runAsUser): ">0"

  YAML
  depends_on = [
    helm_release.kyverno
  ]
}

resource "kubectl_manifest" "restrict-volume-types" {

  yaml_body = <<-YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: restrict-volume-types
    annotations:
      policies.kyverno.io/title: Restrict Volume Types
      policies.kyverno.io/category: Pod Security Standards (Restricted)
      policies.kyverno.io/severity: medium
      policies.kyverno.io/subject: Pod,Volume
      policies.kyverno.io/minversion: 1.6.0
      kyverno.io/kubernetes-version: "1.22-1.23"
      kyverno.io/kyverno-version: 1.6.0
      policies.kyverno.io/description: >-
        In addition to restricting HostPath volumes, the restricted pod security profile
        limits usage of non-core volume types to those defined through PersistentVolumes.
        This policy blocks any other type of volume other than those in the allow list.
  spec:
    validationFailureAction: audit
    background: true
    rules:
      - name: restricted-volumes
        match:
          any:
          - resources:
              kinds:
                - Pod
        validate:
          message: >-
            Only the following types of volumes may be used: configMap, csi, downwardAPI,
            emptyDir, ephemeral, persistentVolumeClaim, projected, and secret.
          deny:
            conditions:
              all:
              - key: "{{ request.object.spec.volumes[].keys(@)[] || '' }}"
                operator: AnyNotIn
                value:
                - name
                - configMap
                - csi
                - downwardAPI
                - emptyDir
                - ephemeral
                - persistentVolumeClaim
                - projected
                - secret
                - ''
  YAML
  depends_on = [
    helm_release.kyverno
  ]
}

resource "kubectl_manifest" "require-ro-rootfs" {

  yaml_body = <<-YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: require-ro-rootfs
    annotations:
      policies.kyverno.io/title: Require Read-Only Root Filesystem
      policies.kyverno.io/category: Best Practices
      policies.kyverno.io/severity: medium
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: >-
        A read-only root file system helps to enforce an immutable infrastructure strategy;
        the container only needs to write on the mounted volume that persists the state.
        An immutable root filesystem can also prevent malicious binaries from writing to the
        host system. This policy validates that containers define a securityContext
        with `readOnlyRootFilesystem: true`.      
  spec:
    validationFailureAction: audit
    background: true
    rules:
    - name: validate-readOnlyRootFilesystem
      match:
        resources:
          kinds:
          - Pod
      validate:
        message: "Root filesystem must be read-only."
        pattern:
          spec:
            containers:
            - securityContext:
                readOnlyRootFilesystem: true

  YAML
  depends_on = [
    helm_release.kyverno
  ]
}

resource "kubectl_manifest" "restrict-binding-clusteradmin" {

  yaml_body = <<-YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: restrict-binding-clusteradmin
    annotations:
      policies.kyverno.io/title: Restrict Binding to Cluster-Admin
      policies.kyverno.io/category: Security
      policies.kyverno.io/severity: medium
      policies.kyverno.io/subject: RoleBinding, ClusterRoleBinding, RBAC
      kyverno.io/kyverno-version: 1.6.2
      policies.kyverno.io/minversion: 1.6.0
      kyverno.io/kubernetes-version: "1.23"
      policies.kyverno.io/description: >-
        The cluster-admin ClusterRole allows any action to be performed on any resource
        in the cluster and its granting should be heavily restricted. This
        policy prevents binding to the cluster-admin ClusterRole in
        RoleBinding or ClusterRoleBinding resources.      
  spec:
    validationFailureAction: enforce
    background: true
    rules:
      - name: clusteradmin-bindings
        match:
          any:
          - resources:
              kinds:
                - RoleBinding
                - ClusterRoleBinding
        validate:
          message: "Binding to cluster-admin is not allowed."
          pattern:
            roleRef: 
              name: "!cluster-admin"

  YAML
  depends_on = [
    helm_release.kyverno
  ]
}

resource "kubectl_manifest" "drop-all-capabilities" {

  yaml_body = <<-YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: drop-all-capabilities
    annotations:
      policies.kyverno.io/title: Drop All Capabilities
      policies.kyverno.io/category: Best Practices
      policies.kyverno.io/severity: medium
      policies.kyverno.io/minversion: 1.6.0
      policies.kyverno.io/subject: Pod
      policies.kyverno.io/description: >-
        Capabilities permit privileged actions without giving full root access. All
        capabilities should be dropped from a Pod, with only those required added back.
        This policy ensures that all containers explicitly specify the `drop: ["ALL"]`
        ability.            
  spec:
    validationFailureAction: audit
    background: true
    rules:
      - name: require-drop-all
        match:
          any:
          - resources:
              kinds:
                - Pod
        preconditions:
          all:
          - key: "{{ request.operation }}"
            operator: NotEquals
            value: DELETE
        validate:
          message: >-
                      Containers must drop `ALL` capabilities.
          foreach:
            - list: request.object.spec.[ephemeralContainers, initContainers, containers][]
              deny:
                conditions:
                  all:
                  - key: ALL
                    operator: AnyNotIn
                    value: "{{ element.securityContext.capabilities.drop || '' }}"

  YAML
  depends_on = [
    helm_release.kyverno
  ]
}

resource "kubectl_manifest" "restrict-binding-system-groups" {

  yaml_body = <<-YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: restrict-binding-system-groups
    annotations:
      policies.kyverno.io/title: Restrict Binding System Groups
      policies.kyverno.io/category: Security
      policies.kyverno.io/severity: medium
      policies.kyverno.io/subject: RoleBinding, ClusterRoleBinding, RBAC
      kyverno.io/kyverno-version: 1.8.0
      policies.kyverno.io/minversion: 1.6.0
      kyverno.io/kubernetes-version: "1.23"
      policies.kyverno.io/description: >-
        Certain system groups exist in Kubernetes which grant permissions that
        are used for certain system-level functions yet typically never appropriate
        for other users. This policy prevents creating bindings to some of these
        groups including system:anonymous, system:unauthenticated, and system:masters.      
  spec:
    validationFailureAction: enforce
    background: true
    rules:
      - name: restrict-anonymous
        match:
          any:
          - resources:
              kinds:
                - RoleBinding
                - ClusterRoleBinding
        validate:
          message: "Binding to system:anonymous is not allowed."
          pattern:
            roleRef:
              name: "!system:anonymous"
      - name: restrict-unauthenticated
        match:
          any:
          - resources:
              kinds:
                - RoleBinding
                - ClusterRoleBinding
        validate:
          message: "Binding to system:unauthenticated is not allowed."
          pattern:
            roleRef:
              name: "!system:unauthenticated"
      - name: restrict-masters
        match:
          any:
          - resources:
              kinds:
                - RoleBinding
                - ClusterRoleBinding
        validate:
          message: "Binding to system:masters is not allowed."
          pattern:
            roleRef:
              name: "!system:masters"

  YAML
  depends_on = [
    helm_release.kyverno
  ]
}
