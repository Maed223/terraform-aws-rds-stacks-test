variable "db_name" {
  description = "Unique name to assign to RDS instance"
}

variable "db_username" {
  description = "RDS root username"
}

variable "db_password" {
  description = "RDS root user password"
  sensitive   = true
}

//The no-code provisioning workflow prompts users to set values for the module's input variables that do not have defaults before creating the new workspace and deploying resources. Users will be able to override any variable values with defaults in future runs. The new workspace will also access any global variable sets in your organization, giving you another way to set configuration defaults.

# variable "db_encrypted" {
#   description = "Encrypt the database storage"
#   type = bool
# }
