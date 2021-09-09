variable "region" {
  default     = "us-west-2"
  description = "AWS region"
}

variable "cluster_name" {
  description = "Name of cluster"
  type = string
  validation {
    condition = can(regex("^[a-z0-9][a-z0-9-]{3,31}$", var.cluster_name))
    error_message = "The cluster_name must be alpha-numeric, allowing hyphenated words."
  }
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

variable "use_spot_block" {
  type = bool
  default = true
}