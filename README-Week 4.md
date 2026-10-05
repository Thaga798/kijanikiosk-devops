# Week 4 Submission Guide

This README is a short guide to my Week 4 work in the KijaniKiosk DevOps repository.

**Repository:** `Thaga798/kijanikiosk-devops`

## Tuesday — Terraform Foundation

**Branch:** `week4/Tuesday`

The week started with setting up the Terraform project and establishing the foundation for managing the KijaniKiosk infrastructure as code.

## Wednesday — Terraform Infrastructure

**Branch:** `week4/Wednesday`

I expanded the Terraform configuration to manage the API, Payments, and Logs servers. This included reusable modules, variables and outputs, remote state using local MinIO, and infrastructure testing.

## Thursday — Ansible Configuration

**Branch:** `week4/Thursday`

I used Ansible to configure all three KijaniKiosk servers, including service accounts, directories, systemd services, firewall rules, logging, and log rotation.

The playbook was run twice, with the second run completing with zero changes and zero failures on all three servers, confirming idempotency.

## Friday — Full IaC Pipeline

**Branch:** `feature/week4-iac-pipeline`

Friday brought the Terraform and Ansible work together into a complete Infrastructure as Code pipeline, including automation, security hardening, verification, and supporting documentation.
