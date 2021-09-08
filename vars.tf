variable "region" {
  default     = "us-west-2"
  description = "AWS region"
}

variable "cluster_name" {
  description = "Name of cluster"
  type = string
}

variable "skip_create_eks" {
  type = bool
  default = false
}

variable "kubernetes_version" {
  type = string
  default = "1.21"
}

variable "use_nat_gateway" {
  type = bool
  default = true
}

variable "enable_autoscaling" {
  type = bool
  default = true
}

