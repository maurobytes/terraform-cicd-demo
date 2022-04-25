variable "administrator_login" {
  description = "The administrator login for the PostgreSQL server"
  type        = string
  sensitive   = true
}

variable "administrator_login_password" {
  description = "The administrator password for the PostgreSQL server"
  type        = string
  sensitive   = true
}
