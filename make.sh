authoirztion-UAT-Blue() {
    export NAMESPACE=UAT
    export IMAGE=377816764053.dkr.ecr.us-east-1.amazonaws.com/authorization:RC-20250428-1816
    envsubst < k8s/secret-db-password.yaml | kubectl apply -f -
    envsubst < k8s/authorizationDeployment.yaml | kubectl apply -f -
    envsubst < k8s/authorizationService.yaml | kubectl apply -f -
}

backend-UAT-Blue() {
    export NAMESPACE=UAT
    export IMAGE=377816764053.dkr.ecr.us-east-1.amazonaws.com/backend:RC-20250428-1816
    envsubst < k8s/secret-db-password.yaml | kubectl apply -f -
    envsubst < k8s/backendDeployment.yaml | kubectl apply -f -
    envsubst < k8s/backendService.yaml | kubectl apply -f -
}

frontedn-UAT-Blue() {
    export NAMESPACE=UAT
    export IMAGE=377816764053.dkr.ecr.us-east-1.amazonaws.com/frontend:RC-20250428-1816
    envsubst < k8s/frontendDeploment.yaml | kubectl apply -f -
    envsubst < k8s/frontentService.yaml | kubectl apply -f -
}