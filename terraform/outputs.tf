output "resource_group_name" {
  description = "Resource Group name"
  value       = azurerm_resource_group.main.name
}

output "acr_name" {
  description = "Container Registry name"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Container Registry login server"
  value       = azurerm_container_registry.acr.login_server
}

output "aks_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "application_gateway_public_ip" {
  description = "Application Gateway public IP address"
  value       = azurerm_public_ip.appgw.ip_address
}

output "application_gateway_name" {
  description = "Application Gateway name"
  value       = azurerm_application_gateway.main.name
}

output "get_aks_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}
