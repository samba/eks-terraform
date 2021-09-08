#!/bin/bash
# see also: https://github.com/terraform-aws-modules/terraform-aws-eks

set -euf -o pipefail

mkdir -p ./temp

terraform init
terraform apply  -auto-approve -input=false -var cluster_name=test 

# Sets up the kubeconfig credentials for API access
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)


setup_metrics () {
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability.yaml
}

setup_dashboard(){
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
kubectl apply -f ./kubernetes-dashboard-admin.rbac.yaml

# Gets the token for kube-dashboard login
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep service-controller-token | awk '{print $1}') | grep 'token:' > token.txt

cat token.txt

}

setup_autoscaler(){

helm uninstall -n kube-system cluster-autoscaler || true
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
helm install cluster-autoscaler --namespace kube-system autoscaler/cluster-autoscaler --values <(terraform output -raw autoscaler_values)
sleep 10
kubectl --namespace=kube-system get pods -l "app.kubernetes.io/name=aws-cluster-autoscaler"

}





setup_metrics
setup_dashboard
setup_autoscaler