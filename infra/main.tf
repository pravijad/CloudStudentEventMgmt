locals {
  name = "${var.project}-${var.environment}"
  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${local.name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = local.tags
}

module "frontend" {
  source              = "./modules/web-app"
  name                = "app-${local.name}-web-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  tags                = local.tags
}

module "backend" {
  source              = "./modules/web-app"
  name                = "app-${local.name}-api-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  tags                = local.tags

  app_settings = {
    NODE_ENV                 = "production"
    DB_HOST                  = azurerm_postgresql_flexible_server.main.fqdn
    DB_PORT                  = "5432"
    DB_NAME                  = azurerm_postgresql_flexible_server_database.app.name
    DB_USER                  = azurerm_postgresql_flexible_server.main.administrator_login
    DB_PASSWORD              = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_password.versionless_id})"
    JWT_SECRET               = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.jwt_secret.versionless_id})"
    CORS_ORIGIN              = "https://${module.frontend.default_hostname}"
    AZURE_STORAGE_ACCOUNT    = azurerm_storage_account.main.name
    AZURE_STORAGE_ACCESS_KEY = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_key.versionless_id})"
    AZURE_CONTAINER_NAME     = azurerm_storage_container.assets.name
  }
}

moved {
  from = azurerm_linux_web_app.frontend
  to   = module.frontend.azurerm_linux_web_app.this
}

moved {
  from = azurerm_linux_web_app.backend
  to   = module.backend.azurerm_linux_web_app.this
}

resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "-_"
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${local.name}-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "16"
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  administrator_login    = "eventadmin"
  administrator_password = random_password.db.result
  tags                   = local.tags

  lifecycle {
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = "student_events"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "my_ip" {
  name             = "allow-my-ip"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = var.my_ip
  end_ip_address   = var.my_ip
}

resource "azurerm_storage_account" "main" {
  name                            = "st${var.project}${var.environment}${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = true
  tags                            = local.tags
}

resource "azurerm_storage_container" "assets" {
  name                  = "event-assets"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "blob"
}

resource "random_password" "jwt" {
  length  = 48
  special = false
}

# ---------- Step 9: Key Vault ----------

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = "kv-${local.name}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  tags                       = local.tags
}

resource "azurerm_role_assignment" "me_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.kv_admin_object_id
}

resource "azurerm_role_assignment" "backend_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.backend.principal_id
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.db.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.me_secrets_officer]
}

resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-secret"
  value        = random_password.jwt.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.me_secrets_officer]
}

resource "azurerm_key_vault_secret" "storage_key" {
  name         = "storage-key"
  value        = azurerm_storage_account.main.primary_access_key
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.me_secrets_officer]
}