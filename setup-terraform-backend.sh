#!/bin/bash

# Setup Terraform Backend Storage Account

echo "=================================================="
echo "Setting up Terraform Backend Storage"
echo "=================================================="
echo ""

# Variables
LOCATION="eastus"
BACKEND_RG="rg-terraform-state"
STORAGE_ACCOUNT="sttfstate$(date +%s)"
CONTAINER_NAME="tfstate"

echo "Configuration:"
echo "  Location: $LOCATION"
echo "  Resource Group: $BACKEND_RG"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Container: $CONTAINER_NAME"
echo ""

# Check if logged in
if ! az account show &> /dev/null; then
    echo "Error: Not logged in to Azure"
    echo "Please run: az login"
    exit 1
fi

# Create resource group
echo "Creating resource group..."
az group create \
  --name $BACKEND_RG \
  --location $LOCATION

echo ""

# Create storage account
echo "Creating storage account..."
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $BACKEND_RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob

echo ""

# Get storage key
echo "Getting storage key..."
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $BACKEND_RG \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' -o tsv)

# Create container
echo "Creating container..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY

echo ""
echo "============================================"
echo "✅ Terraform Backend Setup Complete!"
echo "============================================"
echo ""
echo "📋 Configuration Details:"
echo "  Resource Group: $BACKEND_RG"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Container: $CONTAINER_NAME"
echo "  State File Key: banking-app.tfstate"
echo ""
echo "⚠️  IMPORTANT: Save these values!"
echo ""
echo "Update your pipeline variables with:"
echo "  tfBackendResourceGroup: $BACKEND_RG"
echo "  tfBackendStorageAccount: $STORAGE_ACCOUNT"
echo "  tfBackendContainerName: $CONTAINER_NAME"
echo "  tfBackendKey: banking-app.tfstate"
echo ""
echo "============================================"
