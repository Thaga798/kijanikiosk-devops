# KijaniKiosk Cloud Architecture Decisions
Author: Ed (DevOps)
Date: September 27, 2026

We're mapping out how the KijaniKiosk infrastructure should adapt as the platform scales. Below are the architectural decisions and trade-offs we've evaluated for the upcoming migration.

## 1. Choosing a Service Model (PaaS vs IaaS)
Instead of managing individual virtual machines manually, we are moving the core Node.js order/payment API to a Managed Runtime Platform (PaaS). 

What changes operationally:
- The cloud vendor takes over OS updates, kernel patching, provisioning hardware, and baseline horizontal scaling rules.
- Our team remains responsible for writing the application logic, optimizing database queries, handling API route security, and managing environment secrets.

Trade-offs:
- The big win here is speed. We can deploy directly via Git hooks without writing 200 lines of setup scripts.
- The limitation is that we lose root-level OS customisation. If we ever need to install non-standard networking modules, we are bound by what the PaaS runtime allows.

## 2. Latency & Regional Placement
Since the vast majority of our active sellers and buyers are inside Kenya and East Africa, physical location matters heavily due to network transit times.

Shortlisted Regions:
1. AWS Cape Town (af-south-1)
2. Azure Johannesburg

Why this matters:
Every extra thousand miles of fiber optic cable adds propagation delay. If we host the backend in a US region (like N. Virginia), packets have to travel across transatlantic cables, driving our baseline round-trip times from ~40ms up to a sluggish 230ms. Keeping it on the continent ensures a snappy interface for our users.

Rule of thumb for the team: Always position data nodes physically closest to where the active user base is clustered.

## 3. Designing for Availability Zone (AZ) Outages
If a single data center facility loses power or drops its network link, running our app in a single zone means an immediate system outage. 

To mitigate this, we deploy the API across two independent Availability Zones within the same region. Because these zones use isolated power grids and flood-plains, a failure in Zone A won't crash Zone B.

Simplified Infrastructure Layout:
- Public traffic hits an Application Load Balancer (ALB).
- The ALB splits requests between two app instances: API Instance A (in AZ-1) and API Instance B (in AZ-2).
- For state preservation, the Primary Database lives in AZ-1 and streams data continuously via synchronous replication to a Standby Database Replica in AZ-2. If AZ-1 drops, the replica instantly promotes to primary.

## 4. The Multi-Region Dilemma
The founders suggested deploying to multiple geographic regions immediately to eliminate downtime everywhere. We advise against this at our current scale.

Multi-region architectures add immense operational friction. You have to deal with complex global Anycast DNS routing, asynchronous database replication over thousands of miles, and data inconsistency issues. 

Recommendation: 
We should stick to a highly resilient Single-Region, Multi-AZ design for now. It keeps our costs predictable and provides 99.99% infrastructure protection. We can evaluate an actual multi-region expansion only when our user traffic scales significantly out of East Africa.

