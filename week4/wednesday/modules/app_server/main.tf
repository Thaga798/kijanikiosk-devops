resource "null_resource" "this" {
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
      "echo 'Connected to ${var.name} (${var.environment})'",
      "uname -a"
    ]
  }
}
