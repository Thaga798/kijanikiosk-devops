# KijaniKiosk Network Topology

## Network Design

The KijaniKiosk network is divided into public and private areas.

The public subnet is the part of the network that can communicate with the internet through an Internet Gateway. It can be used for resources that need controlled internet access.

The private subnet is used for application resources that should not be directly accessible from the internet.

## Basic Layout


Internet
   |
Internet Gateway
   |
Public Subnet
   |
Private Subnet
   |
Application Resources

##Public Subnet

The public subnet can contain resources such as a load balancer or other components that need to receive controlled traffic from the internet.

##Private Subnet

The private subnet contains application resources that should not have direct public access.

This helps reduce the attack surface of the application.

##Routing

Internet traffic enters through the Internet Gateway and reaches resources in the public subnet according to the configured routing rules.

Private resources should not have a direct route that allows unrestricted inbound internet traffic.

If private resources need to access the internet for updates or external services, a controlled outbound path such as a NAT Gateway can be considered.

##Security Decision

The main security decision is to separate public-facing resources from internal application resources.

This means that even if a public-facing component is exposed, the application resources in the private subnet are not directly exposed to the internet.

This design can be expanded later by adding multiple Availability Zones, load balancing, monitoring, and additional security controls.
