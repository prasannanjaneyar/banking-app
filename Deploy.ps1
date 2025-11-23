# Manual Build, Push and Deploy Script (PowerShell)
# Simplified Banking Application

param(
    [string]$ImageTag = "latest"
)

Write-Host "==================================================" -ForegroundColor Blue
Write-Host "🚀 Banking App - Manual Deployment" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue
Write-Host ""

# Configuration
$RESOURCE_GROUP = "banking-app"
$ACR_NAME = "bankingacr"
$AKS_NAME = "banking-aks"
$NAMESPACE = "banking"

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Resource Group: $RESOURCE_GROUP"
Write-Host "  ACR: $ACR_NAME"
Write-Host "  AKS: $AKS_NAME"
Write-Host "  Namespace: $NAMESPACE"
Write-Host "  Image Tag: $ImageTag"
Write-Host ""

# Check Azure CLI
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Azure CLI not installed" -ForegroundColor Red
    exit 1
}

# Check if logged in
try {
    az account show | Out-Null
    Write-Host "✓ Azure CLI configured" -ForegroundColor Green
} catch {
    Write-Host "Error: Not logged in to Azure" -ForegroundColor Red
    Write-Host "Run: az login"
    exit 1
}

Write-Host ""

# Step 1: Build and Push Image
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "Step 1: Building and Pushing Docker Image" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue
Write-Host ""

if (!(Test-Path "app")) {
    Write-Host "Error: app directory not found" -ForegroundColor Red
    Write-Host "Please run this script from the banking-app-simplified directory"
    exit 1
}

Write-Host "Building image in ACR..." -ForegroundColor Cyan
az acr build `
  --registry $ACR_NAME `
  --image banking-app:$ImageTag `
  --file Dockerfile `
  --platform linux `
  ./app

Write-Host ""
Write-Host "✓ Image pushed to ACR" -ForegroundColor Green
Write-Host ""

# Verify image
Write-Host "Verifying image in ACR..." -ForegroundColor Cyan
az acr repository show-tags `
  --name $ACR_NAME `
  --repository banking-app `
  --output table

Write-Host ""

# Step 2: Get AKS Credentials
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "Step 2: Getting AKS Credentials" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue
Write-Host ""

az aks get-credentials `
  --resource-group $RESOURCE_GROUP `
  --name $AKS_NAME `
  --overwrite-existing

Write-Host "✓ AKS credentials configured" -ForegroundColor Green
Write-Host ""

# Verify connection
Write-Host "Testing AKS connection..." -ForegroundColor Cyan
kubectl cluster-info
Write-Host ""
kubectl get nodes
Write-Host ""

# Step 3: Update Deployment Manifest
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "Step 3: Updating Kubernetes Manifests" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue
Write-Host ""

Set-Location k8s

# Get ACR login server
$ACR_LOGIN_SERVER = "$ACR_NAME.azurecr.io"

# Backup original
Copy-Item 02-deployment.yaml 02-deployment.yaml.bak -ErrorAction SilentlyContinue

# Update image in deployment
$content = Get-Content 02-deployment.yaml
$content = $content -replace "image:.*", "image: $ACR_LOGIN_SERVER/banking-app:$ImageTag"
$content | Set-Content 02-deployment.yaml

Write-Host "✓ Updated deployment with image: $ACR_LOGIN_SERVER/banking-app:$ImageTag" -ForegroundColor Green
Write-Host ""

# Step 4: Deploy to Kubernetes
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "Step 4: Deploying to Kubernetes" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue
Write-Host ""

# Create namespace
Write-Host "Creating namespace..." -ForegroundColor Cyan
kubectl apply -f 00-namespace.yaml

# Deploy ConfigMap
Write-Host "Deploying ConfigMap..." -ForegroundColor Cyan
kubectl apply -f 01-configmap.yaml

# Deploy Application
Write-Host "Deploying application..." -ForegroundColor Cyan
kubectl apply -f 02-deployment.yaml

# Deploy Service
Write-Host "Deploying service..." -ForegroundColor Cyan
kubectl apply -f 03-service.yaml

Write-Host ""
Write-Host "✓ Resources deployed" -ForegroundColor Green
Write-Host ""

# Wait for deployment
Write-Host "Waiting for deployment to complete..." -ForegroundColor Cyan
kubectl rollout status deployment/banking-app -n $NAMESPACE --timeout=10m

Write-Host ""
Write-Host "✓ Deployment ready" -ForegroundColor Green
Write-Host ""

# Check pods
Write-Host "Pod status:" -ForegroundColor Cyan
kubectl get pods -n $NAMESPACE
Write-Host ""

# Step 5: Get LoadBalancer IP
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "Step 5: Waiting for LoadBalancer IP" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue
Write-Host ""

Write-Host "Waiting for LoadBalancer IP (this may take 5-10 minutes)..." -ForegroundColor Cyan

$INTERNAL_LB_IP = ""
for ($i = 1; $i -le 60; $i++) {
    $INTERNAL_LB_IP = kubectl get svc banking-app-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    
    if ($INTERNAL_LB_IP) {
        Write-Host "✓ LoadBalancer IP: $INTERNAL_LB_IP" -ForegroundColor Green
        break
    }
    
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 10
}

Write-Host ""

if (!$INTERNAL_LB_IP) {
    Write-Host "⚠️  LoadBalancer IP not assigned yet" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Check status with:"
    Write-Host "  kubectl get svc banking-app-service -n $NAMESPACE -w"
    Write-Host ""
    Set-Location ..
    exit 0
}

Write-Host ""

# Step 6: Update Application Gateway
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "Step 6: Configuring Application Gateway" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue
Write-Host ""

$APP_GW_NAME = az network application-gateway list `
  --resource-group $RESOURCE_GROUP `
  --query "[0].name" -o tsv

Write-Host "Application Gateway: $APP_GW_NAME" -ForegroundColor Cyan
Write-Host "Updating backend pool with: $INTERNAL_LB_IP" -ForegroundColor Cyan
Write-Host ""

az network application-gateway address-pool update `
  --gateway-name $APP_GW_NAME `
  --resource-group $RESOURCE_GROUP `
  --name backend-pool `
  --servers $INTERNAL_LB_IP

Write-Host "✓ Application Gateway configured" -ForegroundColor Green
Write-Host ""

# Get Public IP
$APP_GW_PUBLIC_IP = az network public-ip show `
  --resource-group $RESOURCE_GROUP `
  --name banking-appgw-pip `
  --query ipAddress -o tsv

Set-Location ..

# Final Summary
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "✅ DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Application URL:" -ForegroundColor Cyan
Write-Host "   http://$APP_GW_PUBLIC_IP" -ForegroundColor White
Write-Host ""
Write-Host "🔐 Login Credentials:" -ForegroundColor Cyan
Write-Host "   Customer ID: 5439090" -ForegroundColor White
Write-Host "   Password: Passw0rd!!" -ForegroundColor White
Write-Host ""
Write-Host "📊 Deployment Details:" -ForegroundColor Cyan
Write-Host "   Resource Group: $RESOURCE_GROUP"
Write-Host "   ACR: $ACR_LOGIN_SERVER"
Write-Host "   AKS: $AKS_NAME"
Write-Host "   Namespace: $NAMESPACE"
Write-Host "   Image: $ACR_LOGIN_SERVER/banking-app:$ImageTag"
Write-Host "   Internal LB: $INTERNAL_LB_IP"
Write-Host "   Public IP: $APP_GW_PUBLIC_IP"
Write-Host ""
Write-Host "🔍 Verify:" -ForegroundColor Cyan
Write-Host "   kubectl get all -n $NAMESPACE"
Write-Host "   kubectl logs -f deployment/banking-app -n $NAMESPACE"
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""

# Health check
$READY_PODS = (kubectl get pods -n $NAMESPACE -l app=banking-app -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}').Split().Count
$DESIRED_PODS = kubectl get deployment banking-app -n $NAMESPACE -o jsonpath='{.spec.replicas}'

Write-Host "Health Check: $READY_PODS/$DESIRED_PODS pods ready" -ForegroundColor Cyan

if ($READY_PODS -eq $DESIRED_PODS) {
    Write-Host "✓ All pods healthy" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some pods not ready yet" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Open http://$APP_GW_PUBLIC_IP in your browser" -ForegroundColor Cyan
Write-Host ""
