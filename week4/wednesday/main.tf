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

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

locals {
  servers = {
    api = {
      vm_ip       = "10.139.243.128"
      environment = "staging"
    }

    payments = {
      vm_ip       = "10.139.243.105"
      environment = "staging"
    }

    logs = {
      vm_ip       = "10.139.243.140"
      environment = "staging"
    }
  }
}

module "app_servers" {
  source   = "./modules/app_server"
  for_each = local.servers

  name        = each.key
  vm_ip       = each.value.vm_ip
  environment = each.value.environment
}
