# IAM Least-Privilege Design - KijaniKiosk

## Introduction

IAM is used to control who or what can access resources in the cloud. One of the main security ideas I learned is the principle of least privilege. This means giving a user or application only the permissions it actually needs.

For KijaniKiosk, I designed a simple IAM role for the application server.

## Application Task

The application may need to store files such as user uploads in an Amazon S3 bucket.

The application should be able to:

- Upload files
- Download files
- Delete files when necessary
- View the files in its own upload folder

It should not have access to unrelated cloud resources.

## Permissions

The application role would be given limited S3 permissions such as:

- s3:GetObject
- s3:PutObject
- s3:DeleteObject
- s3:ListBucket

These permissions would be limited to the KijaniKiosk application bucket and its upload folder.

## What the Application Should Not Access

The application should not have administrator permissions or access to services that it does not need.

For example, the application should not be allowed to:

- Create or delete IAM users
- Change IAM policies
- Access other applications' storage
- Modify the cloud network
- Manage other servers

Giving the application permissions such as "AdministratorAccess" would defeat the purpose of least privilege.

## Why Least Privilege Is Important

Least privilege helps reduce the damage that could happen if an application account or credential was compromised.

For example, if an attacker gained access to the application role, they would only have access to the resources allowed by that role instead of being able to control the entire cloud environment.

This makes the system easier to secure and audit.

## My Design Decision

For KijaniKiosk, I would create a dedicated IAM role for the application and give it only the permissions needed to perform its job.

As the application grows, permissions can be added when there is a real requirement for them. I would avoid giving broad permissions just because they are convenient.

## What I Learned

The main lesson from this exercise is that security should be considered when designing the system, rather than being added at the end.

Giving every application administrator access may make setup easier, but it creates unnecessary security risks. Starting with limited permissions is a safer approach.
