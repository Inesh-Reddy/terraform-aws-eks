# AWS EKS Cluster Wrapper Module

This is a wrapper module around the upstream [terraform-aws-eks](https://github.com/terraform-aws-modules/terraform-aws-eks) module

## Purpose
Purpose for this module is to enforce opinionated defaults on top of the
upstream module and give users some frequently used resource in-built to the
module so that users can create secure and best practice compliant eks clusters
with minimal configuration.

This has been created as part of Project Inception

## Features
This module is 1:1 compatible with the upstream eks module. Any configuration
done in the upstream module will work with this wrapper with minimal to no
changes.

Check out the upstream module [here](https://github.com/terraform-aws-modules/terraform-aws-eks) for feature list, usage instructions and list of
Providers, Resources, Inputs and Outputs

# EKS Managed Node Group 
An EKS managed node group that demonstrates the configurations/customizations offered by the `eks-managed-node-group` sub-module:
- Deploys SSM Daemonset to enable access to nodes.
- Deploys Kyverno Policy engine.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply -var-file="values.tfvars"
```
## Access nodes using SSM
```bash
aws ssm start-session --region <region> --target <instanceId>
```

## List enforced kyverno policies

```bash
kubectl get cpol #clusterpolicy
kubectl get polr -A #policyreport
 ```
### Tear Down & Clean-Up

```bash
terraform destroy -var-file="values.tfvars"
```

# Self Managed Node Groups

Configuration in this directory creates an AWS EKS cluster with various Self Managed Node Groups (AutoScaling Groups): 

- A self managed node group that demonstrates the configurations/customizations offered by the `self-managed-node-group` sub-module

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply -var-file="values.tfvars"
```

## Access nodes using SSM
```bash
aws ssm start-session --region <region> --target <instanceId>
```
### Tear Down & Clean-Up

```bash
$ terraform destroy -var-file="values.tfvars"
```

# Karpenter

Configuration in this directory creates an AWS EKS cluster with [Karpenter](https://karpenter.sh/) provisioned for managing compute resource scaling.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply -var-file="values.tfvars"
```

Once the cluster is up and running, you can check that Karpenter is functioning as intended with the following command:

```bash
# First, make sure you have updated your local kubeconfig
aws eks --region us-east-2 update-kubeconfig --name eks-karpenter

# Second, scale the example deployment
kubectl create deploy nginx --image=nginx --replicas 5 
kubectl scale deployment nginx --replicas 15

# You can watch Karpenter's controller logs with
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter -c controller
```

You should see a new node named `karpenter.sh/provisioner-name/default` eventually come up in the console; this was provisioned by Karpenter in response to the scaled deployment above.

### Tear Down & Clean-Up

Because Karpenter manages the state of node resources outside of Terraform, Karpenter created resources will need to be de-provisioned first before removing the remaining resources with Terraform.

1. Remove the example deployment created above and any nodes created by Karpenter

```bash
kubectl delete deploy nginx
kubectl delete node -l karpenter.sh/provisioner-name=default
```

2. Remove the resources created by Terraform

```bash
$ terraform destroy -var-file="values.tfvars"
```
# terraform-aws-eks
