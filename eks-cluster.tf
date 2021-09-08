resource "aws_kms_key" "eks" {
  description = "EKS Secret Encryption Key"
}



module "eks" {
  source          = "terraform-aws-modules/eks/aws"

  create_eks = ! var.skip_create_eks
  enable_irsa = var.enable_autoscaling

  cluster_name    = local.cluster_name_full
  cluster_version = var.kubernetes_version


  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets

  tags = {
    Cluster = local.cluster_name_full
  }

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  node_groups = {
    spotgroup = {
      platform = "linux"
      desired_capacity = 1
      max_capacity = 10
      min_capacity = 1
      capacity_type  = "SPOT"
      instance_types = ["t3a.micro"] // TODO
      k8s_labels = {
        Cluster = local.cluster_name_full
        NodeClass = "SPOT"
      }
      update_config = {
        max_unavailable_percentage = 50
      }
      
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${local.cluster_name_full}"
          "propagate_at_launch" = "false"
          "value"               = "owned"
        }
      ]
    }
  }


  worker_create_cluster_primary_security_group_rules = true


  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 1
      asg_max_size                  = 10
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${local.cluster_name_full}"
          "propagate_at_launch" = "false"
          "value"               = "owned"
        }
      ]
    },
    {
      name                          = "worker-group-2"
      instance_type                 = "t2.medium"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
      asg_desired_capacity          = 1
      asg_max_size                  = 6
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${local.cluster_name_full}"
          "propagate_at_launch" = "false"
          "value"               = "owned"
        }
      ]
    },
  ]
}


data "aws_eks_cluster" "cluster" {
  count = var.skip_create_eks ? 0 : 1
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.skip_create_eks ? 0 : 1
  name = module.eks.cluster_id
}


