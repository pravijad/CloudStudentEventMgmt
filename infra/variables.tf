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
