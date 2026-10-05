terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "null_resource" "kijanikiosk_api" {
  triggers = {
    ip = var.vm_ip
  }

  connection {
    type        = "ssh"
    host        = var.vm_ip
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/id_ed25519"))
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Connected to kijanikiosk-api (${var.environment})'",
      "uname -a"
    ]
  }
}

