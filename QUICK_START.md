# Banking Application - Quick Start Guide

## 📦 What's Included

This package contains everything you need to deploy a complete banking application on Azure:

```
banking-app-simplified/
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                   # Azure resources
│   ├── variables.tf              # Configuration
│   └── outputs.tf                # Outputs
├── app/                          # Application Code
│   ├── server.js                 # Node.js backend
│   ├── package.json              # Dependencies
│   ├── Dockerfile                # Container definition
│   └── public/
│       ├── login.html           # Login page
│       └── home.html            # Banking dashboard
├── k8s/                          # Kubernetes Manifests
│   ├── 00-namespace.yaml
│   ├── 01-configmap.yaml
│   ├── 02-deployment.yaml
│   └── 03-service.yaml
├── pipelines/
│   ├── azure-pipelines.yml      # Complete CI/CD pipeline
│   └── azure-pipelines-infrastructure.yml  # Infrastructure only
├── setup-terraform-backend.sh   # Backend setup script
├── deploy.sh                     # Manual deployment (Bash)
├── Deploy.ps1                    # Manual deployment (PowerShell)
└── README.md                     # Full documentation
```

---

## 🚀 Deployment Options

### Option 1: Automated via Azure DevOps Pipeline (Recommended)

**Time:** 30-40 minutes

1. **Setup Backend Storage:**
   ```bash
   ./setup-terraform-backend.sh
   ```
   Save the storage account name!

2. **Create Service Principal:**
   ```bash
   az ad sp create-for-rbac \
     --name "banking-app-pipeline" \
     --role Contributor \
     --scopes /subscriptions/$(az account show --query id -o tsv)
   ```
   Save: appId, password, tenant

3. **Setup Azure DevOps:**
   - Create Service Connection: "Azure-ServiceConnection"
   - Create Environments: "banking-infrastructure", "banking-production"
   - Push code to Azure Repos

4. **Create and Run Pipeline:**
   - New Pipeline → Existing YAML file
   - Select: `/pipelines/azure-pipelines.yml`
   - Update variables (storage account name)
   - Run!

**Pipeline will:**
- ✅ Deploy infrastructure (AKS, ACR, VNet, App Gateway)
- ✅ Build Docker image
- ✅ Deploy to Kubernetes
- ✅ Configure Application Gateway
- ✅ Display URL

---

### Option 2: Manual Deployment

**Time:** 45-60 minutes

#### Step 1: Deploy Infrastructure

**Via Pipeline:**
```bash
# Use azure-pipelines-infrastructure.yml
# Or manually with Terraform:
```

**Via Terraform:**
```bash
./setup-terraform-backend.sh
cd terraform
terraform init
terraform plan
terraform apply
cd ..
```

#### Step 2: Build and Deploy Application

**Bash:**
```bash
./deploy.sh
```

**PowerShell:**
```powershell
.\Deploy.ps1
```

**Manual Commands:**
```bash
# Build and push
az acr build \
  --registry bankingacr \
  --image banking-app:latest \
  --file Dockerfile \
  ./app

# Deploy to AKS
az aks get-credentials \
  --resource-group banking-app \
  --name banking-aks

cd k8s
# Update image in 02-deployment.yaml to: bankingacr.azurecr.io/banking-app:latest
kubectl apply -f .

# Wait for LoadBalancer IP
kubectl get svc banking-app-service -n banking -w

# Update Application Gateway
INTERNAL_IP=$(kubectl get svc banking-app-service -n banking -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

az network application-gateway address-pool update \
  --gateway-name banking-appgw \
  --resource-group banking-app \
  --name backend-pool \
  --servers $INTERNAL_IP

# Get public IP
az network public-ip show \
  --resource-group banking-app \
  --name banking-appgw-pip \
  --query ipAddress -o tsv
```

---

## 🎯 What Gets Deployed

### Azure Resources:
- **Resource Group:** banking-app
- **Container Registry:** bankingacr
- **AKS Cluster:** banking-aks (3 nodes, auto-scaling 2-5)
- **Virtual Network:** banking-vnet
- **Application Gateway:** banking-appgw
- **Public IP:** banking-appgw-pip
- **Log Analytics:** banking-logs

### Application Features:
- ✅ Login Authentication
- ✅ Account Dashboard
- ✅ Same Bank Transfer
- ✅ Other Bank Transfer (NEFT/RTGS/IMPS)
- ✅ Personal Loan Application (Up to ₹15L @ 10.5%)
- ✅ Mortgage Loan Application (Up to ₹75L @ 8.5%)
- ✅ Car Loan Application (Up to ₹20L @ 9.0%)

---

## 🌐 Access Application

After deployment:

```bash
# Get public IP
az network public-ip show \
  --resource-group banking-app \
  --name banking-appgw-pip \
  --query ipAddress -o tsv
```

**Access:** `http://<PUBLIC_IP>`

**Login:**
- Customer ID: `5439090`
- Password: `Passw0rd!!`

---

## 🔍 Verification

```bash
# Check infrastructure
az resource list --resource-group banking-app --output table

# Check image in ACR
az acr repository show-tags --name bankingacr --repository banking-app

# Check pods
kubectl get pods -n banking

# Check service
kubectl get svc -n banking

# Check logs
kubectl logs -f deployment/banking-app -n banking
```

---

## 🎯 Resource Names

All resources use your specified names:

```
Resource Group:  banking-app
ACR:            bankingacr
AKS:            banking-aks
Namespace:      banking
Image:          banking-app
```

---

## 💰 Cost Estimate

Monthly costs (East US):
- AKS (3 × D2s_v3): ~$210
- Application Gateway: ~$150
- Container Registry: ~$5
- LoadBalancer: ~$20
- Log Analytics: ~$15
- **Total: ~$400/month**

💡 Delete when not in use to save costs!

---

## 🧹 Cleanup

```bash
# Delete everything
az group delete --name banking-app --yes --no-wait

# Delete backend storage (optional)
az group delete --name rg-terraform-state --yes --no-wait
```

---

## 🔧 Customization

### Change Resource Names:

Edit `terraform/variables.tf`:
```hcl
variable "resource_group_name" {
  default = "your-name"
}
```

### Change Application Port:

Edit `k8s/01-configmap.yaml`:
```yaml
data:
  PORT: "8080"
```

### Change Replicas:

Edit `k8s/02-deployment.yaml`:
```yaml
spec:
  replicas: 5
```

---

## 📚 Documentation Files

- **README.md** - Complete documentation
- **QUICK_START.md** - This file
- **Detailed pipeline guide** - In pipelines/ folder

---

## ⚠️ Troubleshooting

### Pods Not Starting
```bash
kubectl describe pod <pod-name> -n banking
kubectl logs <pod-name> -n banking
```

### Image Not in ACR
```bash
az acr repository list --name bankingacr
# If empty, rebuild:
az acr build --registry bankingacr --image banking-app:latest ./app
```

### LoadBalancer IP Pending
Wait 5-10 minutes, then:
```bash
kubectl get svc banking-app-service -n banking -w
```

### Application Not Accessible
```bash
az network application-gateway show-backend-health \
  --resource-group banking-app \
  --name banking-appgw
```

---

## 📞 Support

**Prerequisites:**
- Azure subscription
- Azure CLI installed
- kubectl installed (for verification)
- Git (for Azure DevOps)

**Requirements:**
- Contributor role on Azure subscription
- Azure DevOps organization (for pipeline)

---

## ✅ Success Checklist

- [ ] Backend storage created
- [ ] Service principal created (if using pipeline)
- [ ] Code pushed to Azure Repos (if using pipeline)
- [ ] Infrastructure deployed
- [ ] Image built and in ACR
- [ ] Application deployed to AKS
- [ ] 3 pods running
- [ ] LoadBalancer has IP
- [ ] Application Gateway configured
- [ ] Application accessible
- [ ] Login works
- [ ] Banking features work

---

## 🎉 You're Ready!

Choose your deployment method:
1. **Pipeline (Recommended):** Setup Azure DevOps and run pipeline
2. **Manual:** Run ./deploy.sh or .\Deploy.ps1

**Complete banking application deployed in 30-40 minutes!** 🚀

---

For detailed instructions, see README.md or pipeline setup guides in pipelines/ folder.
