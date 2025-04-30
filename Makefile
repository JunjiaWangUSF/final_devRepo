NAMESPACE ?= uat
COLOR ?= blue
FRONTEND_IMAGE ?= 164237789350.dkr.ecr.us-east-1.amazonaws.com/frontend:QA-20250430-0010
BACKEND_IMAGE ?= 164237789350.dkr.ecr.us-east-1.amazonaws.com/backend:QA-20250429-2254
AUTHORIZATION_IMAGE ?= 164237789350.dkr.ecr.us-east-1.amazonaws.com/authorization:QA-20250429-2254


deploy-secret:
	@echo "Deploying Secrets..."
	@export NAMESPACE=$(NAMESPACE) && \
	envsubst < k8s/db-secret.yaml | kubectl apply -f -

deploy-authorization:
	@echo "Deploying Authorization (${NAMESPACE}, ${COLOR}) with image ${AUTHORIZATION_IMAGE}..."
	@export IMAGE=$(AUTHORIZATION_IMAGE) && \
	envsubst < k8s/authorization/deployment.yaml | kubectl apply -f -
	@envsubst < k8s/authorization/service.yaml | kubectl apply -f -

deploy-backend:
	@echo "Deploying Backend (${NAMESPACE}, ${COLOR}) with image ${BACKEND_IMAGE}..."
	@export IMAGE=$(BACKEND_IMAGE) && \
	envsubst < k8s/backend/deployment.yaml | kubectl apply -f -
	@envsubst < k8s/backend/service.yaml | kubectl apply -f -

deploy-frontend:
	@echo "Deploying Frontend (${NAMESPACE}, ${COLOR}) with image ${FRONTEND_IMAGE}..."
	@export IMAGE=$(FRONTEND_IMAGE) NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) && \
	envsubst < k8s/frontend-configmap.yaml | kubectl apply -f - && \
	envsubst < k8s/frontend/deployment.yaml | kubectl apply -f - && \
	envsubst < k8s/frontend/service.yaml | kubectl apply -f -

deploy-uat-blue:
	@echo "Deploying UAT (Color: Blue)..."
	make deploy-secret NAMESPACE=uat
	make deploy-authorization NAMESPACE=uat COLOR=blue AUTHORIZATION_IMAGE=$(AUTHORIZATION_IMAGE)
	make deploy-backend NAMESPACE=uat COLOR=blue BACKEND_IMAGE=$(BACKEND_IMAGE)
	make deploy-frontend NAMESPACE=uat COLOR=blue FRONTEND_IMAGE=$(FRONTEND_IMAGE)

deploy-uat-green:
	@echo "Deploying UAT (Color: Green)..."
	make deploy-secret NAMESPACE=uat
	make deploy-authorization NAMESPACE=uat COLOR=green AUTHORIZATION_IMAGE=$(AUTHORIZATION_IMAGE)
	make deploy-backend NAMESPACE=uat COLOR=green BACKEND_IMAGE=$(BACKEND_IMAGE)
	make deploy-frontend NAMESPACE=uat COLOR=green FRONTEND_IMAGE=$(FRONTEND_IMAGE)
