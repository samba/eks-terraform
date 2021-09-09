#!/bin/bash
set -euf -o pipefail



VARFILE="${1:-terraform.tfvars.json}"

# Remove load balancers that Terraform won't handle
while read ns svc; do
    kubectl delete --wait service -n ${ns} ${svc}
done < <(kubectl get services -A | grep LoadBalancer | awk '{ print $1, $2 }')


# Removing storage volumes requires several hierarchal deletions, due to operators and other abstractions.
kubectl delete --wait deployments,statefulsets,replicasets -A --all
kubectl delete --wait pvc,pv -A --all



terraform destroy -auto-approve -input=false -target module.eks.kubernetes_config_map.aws_auth[0] -var-file=${VARFILE}
terraform destroy -auto-approve -input=false  -var-file=${VARFILE} -var skip_create_eks=true