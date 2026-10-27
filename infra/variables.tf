variable "project" {
  type        = string
  description = "Short project name used in resource names"
  default     = "eventapp"
}

variable "environment" {
  type        = string
  description = "Environment name, e.g. dev or prod"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "australiaeast"
}

variable "my_ip" {
  type        = string
  description = "Your public IP, allowed through the database firewall"
}

variable "kv_admin_object_id" {
  type        = string
  description = "Object ID of the person who manages Key Vault secrets"
}
