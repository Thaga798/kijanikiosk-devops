terraform {
  backend "s3" {
    bucket                      = "kijanikiosk-tfstate"
    key                         = "staging/terraform.tfstate"
    region                      = "us-east-1"
    endpoint                    = "http://localhost:9000"
    access_key                  = "minioadmin"
    secret_key                  = "minioadmin"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    force_path_style            = true
  }

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

data "external" "multipass_ips" {
  for_each = var.servers

  program = [
    "${path.module}/scripts/multipass_ip.sh",
    each.value.vm_name
  ]
}

locals {
  servers = {
    for name, server in var.servers :
    name => {
      vm_ip       = data.external.multipass_ips[name].result.ip
      environment = server.environment
    }
  }
}

module "app_servers" {
  source   = "./modules/app_server"
  for_each = local.servers

  name               = each.key
  vm_ip              = each.value.vm_ip
  environment        = each.value.environment
  ssh_user            = var.ssh_user
  ssh_private_key    = var.ssh_private_key
}
