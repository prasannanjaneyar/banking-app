# Banking Application - Production Ready

Simplified banking application with fund transfer and loan application features.

## 🎯 Features

### Net Banking Features:
- **Same Bank Transfer** - Instant transfer within bank
- **Other Bank Transfer** - NEFT/RTGS/IMPS to other banks
- **Personal Loan** - Up to ₹15 lakhs @ 10.5%
- **Mortgage Loan** - Up to ₹75 lakhs @ 8.5%
- **Car Loan** - Up to ₹20 lakhs @ 9.0%

### Technical Features:
- Node.js Express backend
- Responsive HTML/CSS/JS frontend
- Docker containerized
- Kubernetes deployment
- Azure infrastructure (Terraform)
- Azure DevOps CI/CD ready

## 📋 Resource Names

```
Resource Group:  banking-app
ACR:            bankingacr
AKS:            banking-aks
Namespace:      banking
```

## 🚀 Quick Start

### Option 1: Automated Deployment (Bash)

```bash
# 1. Deploy infrastructure (via Azure DevOps pipeline)
# 2. Then run:
chmod +x deploy.sh
./deploy.sh
```

### Option 2: Automated Deployment (PowerShell)

```powershell
# 1. Deploy infrastructure (via Azure DevOps pipeline)
# 2. Then run:
.\Deploy.ps1
```

### Option 3: Manual Step-by-Step

See [MANUAL_DEPLOYMENT.md](MANUAL_DEPLOYMENT.md)

## 📦 Repository Structure

```
banking-app-simplified/
├── app/
│   ├── server.js              # Node.js Express server
│   ├── package.json           # Dependencies
│   ├── Dockerfile             # Container image
│   └── public/
│       ├── login.html         # Login page
│       └── home.html          # Banking dashboard
├── terraform/
│   ├── main.tf               # Infrastructure definition
│   ├── variables.tf          # Configuration variables
│   └── outputs.tf            # Output values
├── k8s/
│   ├── 00-namespace.yaml     # Kubernetes namespace
│   ├── 01-configmap.yaml     # Application config
│   ├── 02-deployment.yaml    # Application deployment
│   └── 03-service.yaml       # LoadBalancer service
├── pipelines/
│   └── azure-pipelines-infrastructure.yml  # Infrastructure pipeline
├── deploy.sh                 # Automated deployment (Bash)
├── Deploy.ps1                # Automated deployment (PowerShell)
└── README.md                 # This file
```

## 🔧 Prerequisites

### For Infrastructure Deployment:
- Azure subscription
- Azure DevOps account
- Service Principal with Contributor access

### For Manual Deployment:
- Azure CLI installed
- kubectl installed
- Docker installed (optional, for local builds)

## 📝 Step-by-Step Guide

### 1. Deploy Infrastructure

**Via Azure DevOps:**

```bash
# 1. Push code to Azure DevOps repo
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main

# 2. Create pipeline from azure-pipelines-infrastructure.yml
# 3. Update variables in pipeline:
#    - azureSubscription: Your service connection name
#    - tfBackendResourceGroup: rg-terraform-state
#    - tfBackendStorageAccount: Your storage account
# 4. Run pipeline
```

**Or via Terraform locally:**

```bash
# Setup backend
./setup-terraform-backend.sh

# Deploy
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Build and Deploy Application

**Automated (Recommended):**

```bash
# Bash
./deploy.sh

# Or PowerShell
.\Deploy.ps1
```

**Manual Commands:**

```bash
# Build and push image
az acr build \
  --registry bankingacr \
  --image banking-app:latest \
  --file Dockerfile \
  ./app

# Get AKS credentials
az aks get-credentials \
  --resource-group banking-app \
  --name banking-aks

# Deploy to Kubernetes
cd k8s
# Update image in 02-deployment.yaml
kubectl apply -f .

# Get LoadBalancer IP
kubectl get svc banking-app-service -n banking

# Update Application Gateway
az network application-gateway address-pool update \
  --gateway-name banking-appgw \
  --resource-group banking-app \
  --name backend-pool \
  --servers <INTERNAL_LB_IP>

# Get public IP
az network public-ip show \
  --resource-group banking-app \
  --name banking-appgw-pip \
  --query ipAddress
```

## 🌐 Access Application

After deployment:

1. Get public IP:
   ```bash
   az network public-ip show \
     --resource-group banking-app \
     --name banking-appgw-pip \
     --query ipAddress -o tsv
   ```

2. Open in browser: `http://<PUBLIC_IP>`

3. Login with:
   - Customer ID: `5439090`
   - Password: `Passw0rd!!`

## 🔍 Verification

### Check Infrastructure:
```bash
az resource list --resource-group banking-app --output table
```

### Check Image in ACR:
```bash
az acr repository show-tags --name bankingacr --repository banking-app
```

### Check Pods:
```bash
kubectl get pods -n banking
kubectl logs -f deployment/banking-app -n banking
```

### Check Service:
```bash
kubectl get svc -n banking
```

## 🎨 Customization

### Change Resource Names:

Edit `terraform/variables.tf`:
```hcl
variable "resource_group_name" {
  default = "your-rg-name"
}

variable "acr_name" {
  default = "youracrname"
}

variable "aks_name" {
  default = "your-aks-name"
}
```

### Change Application Settings:

Edit `k8s/01-configmap.yaml`:
```yaml
data:
  NODE_ENV: "production"
  PORT: "8080"
  APP_NAME: "Your Bank Name"
```

### Change Replicas:

Edit `k8s/02-deployment.yaml`:
```yaml
spec:
  replicas: 5  # Change from 3 to 5
```

## 🔧 Troubleshooting

### Pods Not Starting:
```bash
kubectl describe pod <pod-name> -n banking
kubectl logs <pod-name> -n banking
```

### Image Not in ACR:
```bash
az acr repository list --name bankingacr
# If empty, rebuild:
az acr build --registry bankingacr --image banking-app:latest ./app
```

### LoadBalancer IP Not Assigned:
```bash
# Wait 5-10 minutes, then check:
kubectl get svc banking-app-service -n banking -w
```

### Application Not Accessible:
```bash
# Check Application Gateway backend health:
az network application-gateway show-backend-health \
  --resource-group banking-app \
  --name banking-appgw
```

## 💰 Cost Estimate

Monthly costs (East US region):
- AKS (3 nodes, D2s_v3): ~$210
- Application Gateway: ~$150
- Container Registry: ~$5
- Load Balancer: ~$20
- Log Analytics: ~$15
- **Total: ~$400/month**

## 🧹 Cleanup

```bash
# Delete everything
az group delete --name banking-app --yes --no-wait

# Or via Terraform
cd terraform
terraform destroy
```

## 📚 Additional Documentation

- [Manual Deployment Guide](MANUAL_DEPLOYMENT.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Azure DevOps Setup](AZURE_DEVOPS_SETUP.md)

## 🔐 Security Notes

- Default login credentials are for demo only
- Change credentials in production
- Enable HTTPS for production use
- Implement proper authentication
- Use Azure Key Vault for secrets
- Enable network policies
- Configure RBAC properly

## 📄 License

MIT License - Feel free to use and modify

## 🤝 Support

For issues or questions:
1. Check troubleshooting guide
2. Review Azure/Kubernetes logs
3. Check Azure Portal for resource status

---

**Ready to deploy!** 🚀

Run `./deploy.sh` or `.\Deploy.ps1` after infrastructure is deployed.
