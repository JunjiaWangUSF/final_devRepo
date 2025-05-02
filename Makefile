# Makefile for Blue-Green Deployment with External NGINX LoadBalancer

# Environment Variables
NAMESPACE ?= uat
COLOR ?= blue
VERSION ?= $(shell date +%Y%m%d-%H%M%S)

AUTHORIZATION_IMAGE ?= 164237789350.dkr.ecr.us-east-1.amazonaws.com/authorization:QA-20250501-0204
BACKEND_IMAGE ?= 164237789350.dkr.ecr.us-east-1.amazonaws.com/backend:QA-20250501-0203

FRONTEND_IMAGE ?= 164237789350.dkr.ecr.us-east-1.amazonaws.com/frontend:RC-20250501-0425 



# ========== Individual Component Deployments ==========

deploy-secret:
	@echo "Deploying Secrets..."
	@export NAMESPACE=$(NAMESPACE) && \
	envsubst < k8s/db-secret.yaml | kubectl apply -f -

deploy-authorization:
	@echo "Deploying Authorization (${NAMESPACE}, ${COLOR}, Version: ${VERSION})..."
	@export IMAGE=$(AUTHORIZATION_IMAGE) NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) VERSION=$(VERSION) && \
	envsubst < k8s/authorization/deployment.yaml | kubectl apply -f - && \
	envsubst < k8s/authorization/service.yaml | kubectl apply -f -

deploy-backend:
	@echo "Deploying Backend (${NAMESPACE}, ${COLOR}, Version: ${VERSION})..."
	@export IMAGE=$(BACKEND_IMAGE) NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) VERSION=$(VERSION) && \
	envsubst < k8s/backend/deployment.yaml | kubectl apply -f - && \
	envsubst < k8s/backend/service.yaml | kubectl apply -f -

deploy-frontend:
	@echo "Deploying Frontend (${NAMESPACE}, ${COLOR}, Version: ${VERSION})..."
	@export IMAGE=$(FRONTEND_IMAGE) NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) VERSION=$(VERSION) && \
	envsubst < k8s/frontend/deployment.yaml | kubectl apply -f - && \
	envsubst < k8s/frontend/service.yaml | kubectl apply -f -

update-ingress:
	@echo "Updating Ingress (${NAMESPACE}, ${COLOR}, Version: ${VERSION})..."
	@export NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) VERSION=$(VERSION) && \
	envsubst < k8s/ingress.yaml | kubectl apply -f -

update-ingress-switch:
	@echo "Switching Ingress Traffic to (${COLOR})..."
	@export NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) VERSION=$(VERSION) && \
	envsubst < k8s/ingress-switch.yaml | kubectl apply -f -

# ========== Full Environment Deployments ==========

deploy-uat-blue:
	@echo "Deploying BLUE stack (UAT)..."
	make deploy-secret NAMESPACE=uat
	make deploy-authorization NAMESPACE=uat COLOR=blue VERSION=$(VERSION)
	make deploy-backend NAMESPACE=uat COLOR=blue VERSION=$(VERSION)
	make deploy-frontend NAMESPACE=uat COLOR=blue VERSION=$(VERSION)
	make update-ingress NAMESPACE=uat COLOR=blue VERSION=$(VERSION)

deploy-uat-green:
	@echo "Deploying GREEN stack (UAT)..."
	make deploy-secret NAMESPACE=uat
	make deploy-authorization NAMESPACE=uat COLOR=green VERSION=$(VERSION)
	make deploy-backend NAMESPACE=uat COLOR=green VERSION=$(VERSION)
	make deploy-frontend NAMESPACE=uat COLOR=green VERSION=$(VERSION)
	make update-ingress NAMESPACE=uat COLOR=green VERSION=$(VERSION)

# ========== Traffic Shift and Cleanup ==========
deploy-ga-blue:
	@echo "Deploying BLUE stack (GA)..."
	make deploy-secret NAMESPACE=ga
	make deploy-authorization NAMESPACE=ga COLOR=blue VERSION=$(VERSION)
	make deploy-backend NAMESPACE=ga COLOR=blue VERSION=$(VERSION)
	make deploy-frontend NAMESPACE=ga COLOR=blue VERSION=$(VERSION)
	make update-ingress NAMESPACE=ga COLOR=blue VERSION=$(VERSION)

deploy-ga-green:
	@echo "Deploying GREEN stack (GA)..."
	make deploy-secret NAMESPACE=ga
	make deploy-authorization NAMESPACE=ga COLOR=green VERSION=$(VERSION)
	make deploy-backend NAMESPACE=ga COLOR=green VERSION=$(VERSION)
	make deploy-frontend NAMESPACE=ga COLOR=green VERSION=$(VERSION)
	make update-ingress NAMESPACE=ga COLOR=green VERSION=$(VERSION)


shift-traffic-uat:
	@echo "Shifting traffic to GREEN..."
	@$(eval VERSION := $(shell kubectl get deployments -n uat -o name | \
		grep 'deployment.apps/backend-green-' | \
		sed -E 's|.*-([0-9]{8}-[0-9]{6})|\1|'))
	@echo "Detected GREEN version: $(VERSION)"
	@make update-ingress-switch NAMESPACE=uat COLOR=green VERSION=$(VERSION)
	@$(eval OLD_VERSION := $(shell kubectl get deployments -n uat -o name | \
		grep 'deployment.apps/backend-blue-' | \
		sed -E 's|.*-([0-9]{8}-[0-9]{6})|\1|'))
	@echo "Detected Blue version: $(OLD_VERSION)"
	@echo "Cleaning up old BLUE stack..."
	@kubectl delete deployment authorization-blue-$(OLD_VERSION) -n uat || true; \
	kubectl delete service authorization-service-blue-$(OLD_VERSION) -n uat || true; \
	kubectl delete deployment backend-blue-$(OLD_VERSION) -n uat || true; \
	kubectl delete service backend-service-blue-$(OLD_VERSION) -n uat || true; \
	kubectl delete deployment frontend-blue-$(OLD_VERSION) -n uat || true; \
	kubectl delete service frontend-service-blue-$(OLD_VERSION) -n uat || true

shift-traffic-ga:
	@echo "Shifting traffic to GREEN..."
	@$(eval VERSION := $(shell kubectl get deployments -n ga -o name | \
		grep 'deployment.apps/backend-green-' | \
		sed -E 's|.*-([0-9]{8}-[0-9]{6})|\1|'))
	@echo "Detected GREEN version: $(VERSION)"
	@make update-ingress-switch NAMESPACE=ga COLOR=green VERSION=$(VERSION)
	@$(eval OLD_VERSION := $(shell kubectl get deployments -n ga -o name | \
		grep 'deployment.apps/backend-blue-' | \
		sed -E 's|.*-([0-9]{8}-[0-9]{6})|\1|'))
	@echo "Detected Blue version: $(OLD_VERSION)"
	@echo "Cleaning up old BLUE stack..."
	@kubectl delete deployment authorization-blue-$(OLD_VERSION) -n ga || true; \
	kubectl delete service authorization-service-blue-$(OLD_VERSION) -n ga || true; \
	kubectl delete deployment backend-blue-$(OLD_VERSION) -n ga || true; \
	kubectl delete service backend-service-blue-$(OLD_VERSION) -n ga || true; \
	kubectl delete deployment frontend-blue-$(OLD_VERSION) -n ga || true; \
	kubectl delete service frontend-service-blue-$(OLD_VERSION) -n ga || true