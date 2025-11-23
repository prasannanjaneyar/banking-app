#!/bin/bash

# Manual Build, Push and Deploy Script
# Simplified Banking Application

set -e

echo "=================================================="
echo "🚀 Banking App - Manual Deployment"
echo "=================================================="
echo ""

# Configuration
RESOURCE_GROUP="banking-app"
ACR_NAME="bankingacr"
AKS_NAME="banking-aks"
NAMESPACE="banking"
IMAGE_TAG="${1:-latest}"

echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  ACR: $ACR_NAME"
echo "  AKS: $AKS_NAME"
echo "  Namespace: $NAMESPACE"
echo "  Image Tag: $IMAGE_TAG"
echo ""

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI not installed"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "Error: Not logged in to Azure"
    echo "Run: az login"
    exit 1
fi

echo "✓ Azure CLI configured"
echo ""

# Step 1: Build and Push Image
echo "=================================================="
echo "Step 1: Building and Pushing Docker Image"
echo "=================================================="
echo ""

if [ ! -d "app" ]; then
    echo "Error: app directory not found"
    echo "Please run this script from the banking-app-simplified directory"
    exit 1
fi

echo "Building image in ACR..."
az acr build \
  --registry $ACR_NAME \
  --image banking-app:$IMAGE_TAG \
  --file Dockerfile \
  --platform linux \
  ./app

echo ""
echo "✓ Image pushed to ACR"
echo ""

# Verify image
echo "Verifying image in ACR..."
az acr repository show-tags \
  --name $ACR_NAME \
  --repository banking-app \
  --output table

echo ""

# Step 2: Get AKS Credentials
echo "=================================================="
echo "Step 2: Getting AKS Credentials"
echo "=================================================="
echo ""

az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --overwrite-existing

echo "✓ AKS credentials configured"
echo ""

# Verify connection
echo "Testing AKS connection..."
kubectl cluster-info
echo ""
kubectl get nodes
echo ""

# Step 3: Update Deployment Manifest
echo "=================================================="
echo "Step 3: Updating Kubernetes Manifests"
echo "=================================================="
echo ""

cd k8s

# Get ACR login server
ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"

# Backup original
cp 02-deployment.yaml 02-deployment.yaml.bak 2>/dev/null || true

# Update image in deployment
sed -i "s|image:.*|image: ${ACR_LOGIN_SERVER}/banking-app:${IMAGE_TAG}|g" 02-deployment.yaml

echo "✓ Updated deployment with image: ${ACR_LOGIN_SERVER}/banking-app:${IMAGE_TAG}"
echo ""

# Step 4: Deploy to Kubernetes
echo "=================================================="
echo "Step 4: Deploying to Kubernetes"
echo "=================================================="
echo ""

# Create namespace
echo "Creating namespace..."
kubectl apply -f 00-namespace.yaml

# Deploy ConfigMap
echo "Deploying ConfigMap..."
kubectl apply -f 01-configmap.yaml

# Deploy Application
echo "Deploying application..."
kubectl apply -f 02-deployment.yaml

# Deploy Service
echo "Deploying service..."
kubectl apply -f 03-service.yaml

echo ""
echo "✓ Resources deployed"
echo ""

# Wait for deployment
echo "Waiting for deployment to complete..."
kubectl rollout status deployment/banking-app -n $NAMESPACE --timeout=10m

echo ""
echo "✓ Deployment ready"
echo ""

# Check pods
echo "Pod status:"
kubectl get pods -n $NAMESPACE
echo ""

# Step 5: Get LoadBalancer IP
echo "=================================================="
echo "Step 5: Waiting for LoadBalancer IP"
echo "=================================================="
echo ""

echo "Waiting for LoadBalancer IP (this may take 5-10 minutes)..."

INTERNAL_LB_IP=""
for i in {1..60}; do
  INTERNAL_LB_IP=$(kubectl get svc banking-app-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  
  if [ -n "$INTERNAL_LB_IP" ]; then
    echo "✓ LoadBalancer IP: $INTERNAL_LB_IP"
    break
  fi
  
  echo -n "."
  sleep 10
done

echo ""

if [ -z "$INTERNAL_LB_IP" ]; then
    echo "⚠️  LoadBalancer IP not assigned yet"
    echo ""
    echo "Check status with:"
    echo "  kubectl get svc banking-app-service -n $NAMESPACE -w"
    echo ""
    echo "After IP is assigned, update Application Gateway:"
    echo "  Run: ./update-appgateway.sh"
    cd ..
    exit 0
fi

echo ""

# Step 6: Update Application Gateway
echo "=================================================="
echo "Step 6: Configuring Application Gateway"
echo "=================================================="
echo ""

APP_GW_NAME=$(az network application-gateway list \
  --resource-group $RESOURCE_GROUP \
  --query "[0].name" -o tsv)

echo "Application Gateway: $APP_GW_NAME"
echo "Updating backend pool with: $INTERNAL_LB_IP"
echo ""

az network application-gateway address-pool update \
  --gateway-name $APP_GW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name backend-pool \
  --servers $INTERNAL_LB_IP

echo "✓ Application Gateway configured"
echo ""

# Get Public IP
APP_GW_PUBLIC_IP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP \
  --name banking-appgw-pip \
  --query ipAddress -o tsv)

cd ..

# Final Summary
echo ""
echo "=================================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=================================================="
echo ""
echo "🌐 Application URL:"
echo "   http://$APP_GW_PUBLIC_IP"
echo ""
echo "🔐 Login Credentials:"
echo "   Customer ID: 5439090"
echo "   Password: Passw0rd!!"
echo ""
echo "📊 Deployment Details:"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   ACR: $ACR_LOGIN_SERVER"
echo "   AKS: $AKS_NAME"
echo "   Namespace: $NAMESPACE"
echo "   Image: ${ACR_LOGIN_SERVER}/banking-app:${IMAGE_TAG}"
echo "   Internal LB: $INTERNAL_LB_IP"
echo "   Public IP: $APP_GW_PUBLIC_IP"
echo ""
echo "🔍 Verify:"
echo "   kubectl get all -n $NAMESPACE"
echo "   kubectl logs -f deployment/banking-app -n $NAMESPACE"
echo ""
echo "=================================================="
echo ""

# Health check
READY_PODS=$(kubectl get pods -n $NAMESPACE -l app=banking-app -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
DESIRED_PODS=$(kubectl get deployment banking-app -n $NAMESPACE -o jsonpath='{.spec.replicas}')

echo "Health Check: $READY_PODS/$DESIRED_PODS pods ready"

if [ "$READY_PODS" -eq "$DESIRED_PODS" ]; then
  echo "✓ All pods healthy"
else
  echo "⚠️  Some pods not ready yet"
fi

echo ""
echo "🎉 Deployment Complete!"
echo ""
echo "Open http://$APP_GW_PUBLIC_IP in your browser"
echo ""
