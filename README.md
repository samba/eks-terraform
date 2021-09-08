# Provision EKS clusters with terraform

This is derived from [Learn Terraform Provisioner - EKS Cluster][learn-terraform-eks] and its [companion tutorial][companion].

Objectives:
- Provision full-featured Kubernetes clusters on AWS with sensible defaults.
- Minimize up-front infrastructure costs, leverage spot instances and autoscaling.

In support of these, this derivation has also adopted some changes:
- Autoscaling is configurable via Terraform variable
- NAT gateway usage is configurable via Terraform variable
- Various configuration dependencies are reflected as Terraform outputs



[learn-terraform-eks]: https://github.com/hashicorp/learn-terraform-provision-eks-cluster "learn-terraform-provisioner-eks-cluster"
[companion]: https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster "Provision an EKS Cluster learn guide"