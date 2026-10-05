output "server_ips" {
  description = "IP addresses of all KijaniKiosk servers"
  value = {
    for name, server in module.app_servers :
    name => server.server_ip
  }
}

output "api_server_ip" {
  description = "API server IP address"
  value       = module.app_servers["api"].server_ip
}

output "payments_server_ip" {
  description = "Payments server IP address"
  value       = module.app_servers["payments"].server_ip
}

output "logs_server_ip" {
  description = "Logs server IP address"
  value       = module.app_servers["logs"].server_ip
}

output "ssh_commands" {
  description = "SSH commands for all servers"
  value = {
    for name, server in module.app_servers :
    name => "ssh -i ${pathexpand(var.ssh_private_key)} ${var.ssh_user}@${server.server_ip}"
  }
}
