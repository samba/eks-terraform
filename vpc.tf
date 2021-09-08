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


provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name_full = "${var.cluster_name}-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name                 = "${var.cluster_name}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = var.use_nat_gateway
  single_nat_gateway   = var.use_nat_gateway
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name_full}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name_full}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name_full}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
