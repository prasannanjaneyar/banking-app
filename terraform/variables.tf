variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "banking-app"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "banking"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "bankingacr3456"
}

variable "aks_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "banking-aks"
}

variable "aks_node_count" {
  description = "Initial number of nodes in AKS"
  type        = number
  default     = 3
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "Banking-App"
    ManagedBy   = "Terraform"
  }
}
