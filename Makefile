# Makefile for Blue-Green Deployment with External NGINX LoadBalancer

NAMESPACE ?= uat
COLOR ?= blue
AUTHORIZATION_IMAGE ?= 164237789350.dkr.ecr.us-east-1.amazonaws.com/authorization:QA-20250501-0204
BACKEND_IMAGE ?= 164237789350.dkr.ecr.us-east-1.amazonaws.com/backend:QA-20250501-0203

#FRONTEND_IMAGE ?= 164237789350.dkr.ecr.us-east-1.amazonaws.com/frontend:RC-20250501-0425 #red
FRONTEND_IMAGE ?= 164237789350.dkr.ecr.us-east-1.amazonaws.com/frontend:QA-20250501-0218 #normal




# Deploy DB Secret
deploy-secret:
	@echo "Deploying Secrets..."
	@export NAMESPACE=$(NAMESPACE) && \
	envsubst < k8s/db-secret.yaml | kubectl apply -f -

# Deploy Authorization Service
deploy-authorization:
	@echo "Deploying Authorization (${NAMESPACE}, ${COLOR}) with image ${AUTHORIZATION_IMAGE}..."
	@export IMAGE=$(AUTHORIZATION_IMAGE) NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) && \
	envsubst < k8s/authorization/deployment.yaml | kubectl apply -f - && \
	envsubst < k8s/authorization/service.yaml | kubectl apply -f -

# Deploy Backend Service
deploy-backend:
	@echo "Deploying Backend (${NAMESPACE}, ${COLOR}) with image ${BACKEND_IMAGE}..."
	@export IMAGE=$(BACKEND_IMAGE) NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) && \
	envsubst < k8s/backend/deployment.yaml | kubectl apply -f - && \
	envsubst < k8s/backend/service.yaml | kubectl apply -f -


deploy-frontend:
	@echo "Deploying Frontend (${NAMESPACE}, ${COLOR}) with image ${FRONTEND_IMAGE}..."
	@export IMAGE=$(FRONTEND_IMAGE) NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) && \
	envsubst < k8s/frontend/deployment.yaml | kubectl apply -f - && \
	envsubst < k8s/frontend/service.yaml | kubectl apply -f -
shift-traffic:
	@echo "Shifting Traffic to green..."
	@export IMAGE=$(FRONTEND_IMAGE) NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) && \
	envsubst < k8s/ingress.yaml | kubectl apply -f -

update-ingress:
	@echo "Updating Ingress..."
	@export NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) && \
	envsubst < k8s/ingress.yaml | kubectl apply -f -
update-ingress-switch:
	@echo "Updating Ingress..."
	@export NAMESPACE=$(NAMESPACE) COLOR=$(COLOR) && \
	envsubst < k8s/ingress-switch.yaml | kubectl apply -f -

# Full Blue Deployment
deploy-uat-blue:
	@echo "Deploying UAT (Color: Blue)..."
	make deploy-secret NAMESPACE=uat
	make deploy-authorization NAMESPACE=uat COLOR=blue AUTHORIZATION_IMAGE=$(AUTHORIZATION_IMAGE)
	make deploy-backend NAMESPACE=uat COLOR=blue BACKEND_IMAGE=$(BACKEND_IMAGE)
	make deploy-frontend NAMESPACE=uat COLOR=blue FRONTEND_IMAGE=$(FRONTEND_IMAGE)
	make update-ingress NAMESPACE=uat COLOR=blue 

# Full Green Deployment
deploy-uat-green:
	@echo "Deploying UAT (Color: Green)..."
	make deploy-secret NAMESPACE=uat
	make deploy-authorization NAMESPACE=uat COLOR=green AUTHORIZATION_IMAGE=$(AUTHORIZATION_IMAGE)
	make deploy-backend NAMESPACE=uat COLOR=green BACKEND_IMAGE=$(BACKEND_IMAGE)
	make deploy-frontend NAMESPACE=uat COLOR=green FRONTEND_IMAGE=$(FRONTEND_IMAGE)
	make update-ingress NAMESPACE=uat COLOR=green 

# Shift traffic to Green Deployment	
shift-traffic-uat:
	@echo "Shifting Traffic to green..."
	make update-ingress-switch NAMESPACE=uat COLOR=green 
	kubectl delete deployments authorization-blue --namespace uat
	kubectl delete services authorization-service-blue --namespace uat
	kubectl delete deployments frontend-blue --namespace uat
	kubectl delete services frontend-service-blue --namespace uat
	kubectl delete deployments backend-blue --namespace uat
	kubectl delete services backend-service-blue --namespace uat

clean:
	@echo "Cleaning up..."
	# kubectl delete deployments authorization-blue --namespace uat
	# kubectl delete services authorization-service-blue --namespace uat
	# kubectl delete deployments frontend-blue --namespace uat
	# kubectl delete services frontend-service-blue --namespace uat
	# kubectl delete deployments backend-blue --namespace uat
	# kubectl delete services backend-service-blue --namespace uat

	kubectl delete deployments authorization-green --namespace uat
	kubectl delete services authorization-service-green --namespace uat
	kubectl delete deployments frontend-green --namespace uat
	kubectl delete services frontend-service-green --namespace uat
	kubectl delete deployments backend-green --namespace uat
	kubectl delete services backend-service-green --namespace uat

