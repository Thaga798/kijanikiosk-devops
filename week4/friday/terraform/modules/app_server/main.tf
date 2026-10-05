resource "null_resource" "this" {
  triggers = {
    ip = var.vm_ip
  }

  connection {
    type        = "ssh"
    host        = var.vm_ip
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key))
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Connected to ${var.name} (${var.environment})'",
      "uname -a"
    ]
  }
}
