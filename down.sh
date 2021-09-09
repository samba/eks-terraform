#!/bin/bash
set -euf -o pipefail

# TODO: clean up load balancers & storage volumes created within k8s


VARFILE="${1:-terraform.tfvars.json}"

# After the cluster is partially down, this may be required to unblock deletion:
# terraform taint module.eks.kubernetes_config_map.aws_auth[0]
# terraform state rm module.eks.kubernetes_config_map.aws_auth[0]

terraform destroy -auto-approve -input=false -target module.eks.kubernetes_config_map.aws_auth[0] -var-file=${VARFILE}
terraform destroy -auto-approve -input=false  -var-file=${VARFILE} -var skip_create_eks=true