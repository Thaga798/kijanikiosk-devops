# Cloud Service Model - KijaniKiosk

## 1. Introduction

KijaniKiosk requires a cloud architecture that can support application hosting, networking, security, and future growth. The three main cloud service models considered are Infrastructure as a Service (IaaS), Platform as a Service (PaaS), and Software as a Service (SaaS).

## 2. Selected Model: Infrastructure as a Service (IaaS)

For the initial KijaniKiosk architecture, IaaS is the preferred model.

IaaS provides virtual computing resources such as servers, storage, networking, and security controls while allowing the engineering team to manage the operating system and application environment.

An example implementation would use:

- Virtual machines for application services
- Virtual networks and subnets
- Security groups or firewall rules
- Cloud storage
- IAM roles and policies
- Monitoring and logging services

## 3. Why IaaS Was Selected

IaaS provides the level of control required for the KijaniKiosk platform.

The project involves Linux system administration, network segmentation, security hardening, infrastructure automation, and service isolation. These requirements benefit from having direct control over the operating system and network configuration.

IaaS also makes it possible to reproduce environments using infrastructure-as-code tools as the project grows.

## 4. Comparison With PaaS

PaaS would reduce the amount of operating-system and server administration required. The cloud provider would manage more of the underlying infrastructure while the development team would focus mainly on the application.

PaaS could become useful for KijaniKiosk in the future, particularly for application components where rapid deployment and reduced infrastructure management are more important than operating-system-level control.

However, the initial project requires more infrastructure-level control, making IaaS appropriate for the starter architecture.

## 5. Comparison With SaaS

SaaS provides complete software applications managed by a third-party provider. Examples include collaboration, email, project-management, and communication platforms.

SaaS is useful for supporting business and development activities but is not suitable as the primary hosting model for the KijaniKiosk application because the project requires control over its application infrastructure and networking.

## 6. Decision

The initial KijaniKiosk architecture will use **IaaS** as its primary cloud service model.

The decision is based on:

- Greater control over infrastructure
- Ability to configure Linux systems
- Support for custom networking
- Integration with IAM and security controls
- Support for infrastructure automation
- Flexibility to scale the architecture later

PaaS and SaaS remain useful complementary models where they provide operational benefits without compromising important application requirements.
