variable "environment" {
  type        = string
  description = "Deployment environment"

  default = "staging"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be staging or production."
  }
}

variable "region" {
  type        = string
  description = "Deployment region"
  default     = "local"
}

variable "instance_type" {
  type        = string
  description = "Server instance type"
  default     = "multipass"
}

variable "ssh_key_name" {
  type        = string
  description = "SSH key name used for server access"
  default     = "id_ed25519"
}

variable "ssh_user" {
  type        = string
  description = "SSH user used by Terraform and Ansible"
  default     = "ubuntu"
}

variable "ssh_private_key" {
  type        = string
  description = "Path to the SSH private key"
  default     = "~/.ssh/id_ed25519"
}

variable "servers" {
  description = "KijaniKiosk server definitions"

  type = map(object({
    vm_name     = string
    environment = string
  }))

  default = {
    api = {
      vm_name     = "kijanikiosk-api"
      environment = "staging"
    }

    payments = {
      vm_name     = "kijanikiosk-payments"
      environment = "staging"
    }

    logs = {
      vm_name     = "kijanikiosk-logs"
      environment = "staging"
    }
  }
}
