variable "vm_ip" {
  type        = string
  description = "IP address of the Multipass VM"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be staging or production."
  }
}
