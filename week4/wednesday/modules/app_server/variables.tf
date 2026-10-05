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
