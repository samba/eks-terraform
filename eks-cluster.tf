resource "aws_kms_key" "eks" {
  description = "EKS Secret Encryption Key"
}

resource "aws_kms_key" "rootkey" {
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
    version = var.kubernetes_version
    disk_size = 50
    platform = "linux"
    asg_min_size = 0
    default_cooldown = 180 # 3 minutes
    termination_policies = ["OldestInstance", "OldestLaunchConfiguration", "OldestLaunchTemplate"]
    instance_refresh_enabled = true
    instance_refresh_strategy = "Rolling"
    instance_refresh_min_healthy_percentage = 80

    disk_encrypted = true
    disk_kms_key_id = aws_kms_key.rootkey.id
  }

  node_groups = {
    spotgroup = {
      desired_capacity = 1
      max_capacity = 10
      min_capacity = var.enable_autoscaling ? 1 : 10
      capacity_type  = var.use_spot_block ? "SPOT" : "ON_DEMAND"
      instance_types = ["t3a.micro", "t3a.small", "t3a.medium", "t3a.large"]
      max_instance_lifectime = 86400  # one day
      
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
    platform = "linux"
    asg_min_size = 0
    termination_policies = ["OldestInstance", "OldestLaunchConfiguration", "OldestLaunchTemplate"]
    instance_refresh_enabled = true
    instance_refresh_strategy = "Rolling"
    instance_refresh_min_healthy_percentage = 80
    capacity_rebalance = true
    # instance_refresh_instance_warmup = 60
    default_cooldown = 180 # 3 minutes
    root_encrypted = true
    root_kms_key_id = aws_kms_key.rootkey.id
  }

  worker_groups = [
    {
      name                          = "small ${var.kubernetes_version}"
      instance_type                 = "t3a.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = var.enable_autoscaling ? 1 : 10
      asg_min_size                  = var.enable_autoscaling ? 1 : 10
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
      name                          = "medium ${var.kubernetes_version}"
      instance_type                 = "t3a.medium"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
      asg_desired_capacity          = var.enable_autoscaling ? 0 : 6
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
    {
      name                          = "large ${var.kubernetes_version}"
      instance_type                 = "t3a.large"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
      asg_desired_capacity          = var.enable_autoscaling ? 0 : 6
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


