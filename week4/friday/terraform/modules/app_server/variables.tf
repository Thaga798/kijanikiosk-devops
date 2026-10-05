variable "name" {
  type        = string
  description = "Name of the KijaniKiosk server"
}

variable "vm_ip" {
  type        = string
  description = "IP address of the Multipass VM"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "ssh_user" {
  type        = string
  description = "SSH user for remote provisioning"
}

variable "ssh_private_key" {
  type        = string
  description = "Path to the SSH private key"
}
