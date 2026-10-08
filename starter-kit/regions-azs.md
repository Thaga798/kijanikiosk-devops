# Region and Availability Zone Strategy - KijaniKiosk

## 1. Introduction

KijaniKiosk should be deployed in a cloud region that provides suitable geographic proximity to its primary users while also offering the required cloud services and availability-zone infrastructure.

The architecture should avoid depending on a single availability zone because a failure affecting one zone could make the application unavailable.

## 2. Region Selection

For the initial design, the application will use an AWS region in Africa that is geographically suitable for users in Kenya, subject to the availability of the required AWS services.

The selected region for this design is **Africa (Cape Town) - `af-south-1`**.

The region is appropriate for the initial architecture because it is located within Africa and can provide a closer geographic deployment option than regions located in Europe, North America, or other continents.

The final production region should also be confirmed against:

- Required AWS service availability
- Expected latency
- Data residency requirements
- Cost
- Disaster recovery requirements
- Availability-zone capacity

## 3. Availability Zones

An AWS region contains multiple isolated Availability Zones (AZs). Each AZ represents a separate location designed to provide isolation from failures in other AZs.

The KijaniKiosk architecture should use at least two Availability Zones where the required services support this configuration.

For example:

- Availability Zone A hosts resources for the primary application tier.
- Availability Zone B hosts resources for the redundant application tier.

This reduces dependence on a single physical location within the region.

## 4. Reliability Benefits

Using multiple Availability Zones improves resilience.

If an infrastructure problem affects one Availability Zone, resources in another Availability Zone can continue operating. This is preferable to placing all application resources inside a single AZ.

A multi-AZ design also provides a foundation for:

- Load balancing
- Application redundancy
- High availability
- Rolling deployments
- Maintenance without complete service interruption

## 5. Initial Architecture

The initial network design will contain:

```text
AWS Region: af-south-1
|
+-- Availability Zone A
|   +-- Public Subnet
|   +-- Private Subnet
|
+-- Availability Zone B
    +-- Public Subnet
    +-- Private Subnet 

```

## 6. Growth Strategy

As KijaniKiosk grows, the architecture can be expanded across multiple Availability Zones with redundant application servers, load balancing, managed databases, monitoring, backups, and automated disaster recovery.

The goal is to avoid a single point of failure while keeping the architecture manageable and cost-effective.

## 7. Architecture Decision

The key decision is to use a single suitable AWS region with multiple Availability Zones for the initial production architecture.

This provides a balance between geographic proximity, reliability, operational complexity, and cost. A multi-region disaster-recovery strategy can be considered later if the platform's availability requirements justify the additional complexity and expense.
