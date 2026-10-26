output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "backend_app_name" {
  value = module.backend.name
}

output "frontend_app_name" {
  value = module.frontend.name
}

output "backend_url" {
  value = "https://${module.backend.default_hostname}"
}

output "frontend_url" {
  value = "https://${module.frontend.default_hostname}"
}

output "db_host" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "db_admin_password" {
  value     = random_password.db.result
  sensitive = true
}
