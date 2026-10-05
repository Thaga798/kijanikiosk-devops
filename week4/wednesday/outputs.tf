output "server_ips" {
  description = "IP addresses of all KijaniKiosk servers"
  value = {
    for name, server in module.app_servers :
    name => server.server_ip
  }
}
