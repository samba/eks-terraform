#!/bin/bash
set -euf -o pipefail

# TODO: clean up load balancers & storage volumes created within k8s

terraform destroy