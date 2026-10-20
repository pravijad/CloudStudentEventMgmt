output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "backend_app_name" {
  value = azurerm_linux_web_app.backend.name
}

output "frontend_app_name" {
  value = azurerm_linux_web_app.frontend.name
}

output "backend_url" {
  value = "https://${azurerm_linux_web_app.backend.default_hostname}"
}

output "frontend_url" {
  value = "https://${azurerm_linux_web_app.frontend.default_hostname}"
}

output "db_host" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "db_admin_password" {
  value     = random_password.db.result
  sensitive = true
}