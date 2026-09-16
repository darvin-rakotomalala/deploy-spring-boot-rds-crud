## Deploy Spring Boot CRUD to EC2 + RDS PostgreSQL (Terraform)

This comprehensive project walks you through deploying a Spring Boot CRUD application on Amazon AWS EC2 with PostgreSQL
RDS database. We’ll learn how to:

* Create a production-ready Spring Boot application with CRUD operations
* Set up AWS infrastructure including EC2 and RDS
* Configure security groups to allow proper communication
* Create and attach IAM roles for secure AWS access
* Upload our JAR to S3 for storage
* Deploy and test our application

This end-to-end guide covers every step from development to production deployment.

### Business Problem

***

Organizations deploying Java Spring Boot applications on AWS often default to quick, insecure setups: public-facing EC2
instances with SSH open to the internet, databases reachable directly from outside the VPC, hardcoded AWS credentials in
CI/CD pipelines, plaintext database passwords in application properties, and no encryption at rest or in transit. This
works for a demo, but it fails a production security review and leaves the environment exposed to credential theft,
unauthorized database access, man-in-the-middle attacks, and compliance violations (SOC 2, PCI-DSS, HIPAA, etc.).

Teams need a repeatable, Infrastructure-as-Code pattern that deploys a real CRUD application behind proper network
isolation and end-to-end encryption, with a CI/CD pipeline that deploys to AWS without long-lived access keys — all
without manual console clicking or reinventing security architecture on every project.

### The Challenge

***

Building a genuinely production-ready deployment — not just a "hello world" EC2 instance — requires solving several
problems at once:

* **Network isolation without losing manageability**: keep the application and database tiers fully private (no public
  IPs, no inbound SSH) while still allowing operators to access them for troubleshooting. Solved with SSM Session
  Manager instead of a bastion host, backed by VPC interface endpoints for SSM, EC2 Messages, and SSM Messages, plus a
  PrivateLink connection so operators reach instances through a secure tunnel from their local machine.
* **Encryption everywhere, not just at the edges**: traffic between the user and the ALB is TLS 1.2/1.3 terminated with
  an ACM-issued certificate; traffic from the ALB to the app tier and from the app tier to RDS stays inside the VPC on
  private connections; and data at rest — RDS storage and the S3 buckets holding the JAR and access logs — is encrypted
  with AES-256 keys centrally managed through KMS.
* **Keyless CI/CD**: deploying from GitHub Actions to AWS without storing static IAM access keys as repository secrets.
  Solved using a GitHub OIDC identity provider that lets GitHub Actions assume a scoped IAM role for the duration of
  each deployment (commit → GitHub → GitHub Actions → EC2).
* **Least-privilege access to AWS services**: EC2 needs to read the deployment JAR from S3, decrypt secrets, write logs,
  and talk to RDS — without broad IAM permissions. Solved with a scoped instance role covering only S3, SSM, RDS, KMS,
  Secrets Manager, and CloudWatch.
* **Credential management**: avoid hardcoded database passwords in application config or Terraform state. Solved with
  AWS Secrets Manager for rotated RDS credentials, encrypted with a dedicated KMS key.
* **High availability**: the ALB, application tier, and RDS instance all span two Availability Zones, with RDS running
  Multi-AZ, so a single-AZ failure doesn't take down the application.
* **Terraform module ordering and circular dependencies**: for example, the RDS instance depends on the CloudWatch log
  group name, which depends on the RDS identifier, which depends on the RDS instance — a genuine circular reference
  resolved during implementation (documented in the Troubleshooting section).
* **Observability from day one**: centralized CloudWatch logging for the ALB, application tier, and RDS, with SNS-based
  alerting, rather than bolting monitoring on after the fact.
* **Repeatability and auditability**: the entire stack — VPC, subnets, security groups, NACLs, ALB, EC2, RDS, IAM, KMS,
  Secrets Manager, ACM, CloudWatch, SNS — is defined in Terraform, deployed via GitHub Actions, and validated by Checkov
  in CI/CD, so infrastructure changes are reviewed, scanned for misconfigurations, and reproducible across environments.

### Architecture overview

***

**Core Components**

* **Networking**: VPC with two AZs, public/private/database subnets.
* **ALB public facing**: Application Load Balancer (ALB) in public subnet (2 AZs) for distributing incoming traffic.
* **Application Tier**: EC2 instances backend App Tier in private subnet with SSM agent installed (which has NAT Gateway
  to access internet). **Access via SSM only** — no bastion host, no SSH inbound rule, no public IP on
  the app or DB tiers.
* **Database Tier**: Data Tier RDS PostgreSQL (Multi-AZ) in isolated database subnets.
* **IAM role**: Instance role with policy to allow EC2 access for S3, SSM, RDS, KMS, Secrets Manger and CloudWatch
* **S3** — Stores our application JAR file and for access logs contain detailed information about requests sent to the
  load balancer. Each log contains information such as the time the request was received, the client’s IP address,
  latencies, request paths, and server responses. You can use these access logs to analyze traffic patterns and
  troubleshoot issues.
* **KMS** — KMS key for RDS, Secrets Manger, CloudWatch encryption.
* **AWS Secrets Manager** — to securely store, rotate, and manage database credentials.
* **CloudWatch** — Log group for ALB, App tier and RDS database.
* **SNS** — Shared KMS-encrypted SNS topic + email subscription.
* **VPC endpoints**: for SSM, EC2 messages, and SSM messages.
* **Security groups**: ```ALB-SG```, ```EC2-APP-SG```, ```RDS-SG``` and SSM Interface Endpoints.
* **Security**: Security Groups, NACLs, VPC endpoints, KMS for encryption, IAM roles with the least privilege.

Here is the architecture diagram related to the scenario we are going to address.

![spring-boot-rds-crud.png](spring-boot-rds-crud.png)

**Traffic flow**

```
Internet
   │  HTTPS (443) / HTTP→HTTPS redirect
   ▼
ALB (public subnets, 2 AZs)  ── access logs ──▶ S3 (alb_logs bucket)
   │  HTTP :8080 (ALB-SG → EC2-APP-SG)
   ▼
EC2 Spring Boot app tier (private app subnets, 2 AZs, SSM-only access)
   │  5432 (EC2-APP-SG → RDS-SG)                 │  reads JAR at boot via
   ▼                                             │  S3 Gateway VPC Endpoint
RDS PostgreSQL Multi-AZ (isolated DB subnets, no internet route)      S3 (jar_artifacts bucket)

Cross-cutting: VPC Endpoints (SSM/SSMMessages/EC2Messages/S3), KMS (RDS, Secrets,
CloudWatch), Secrets Manager (rotated DB password), IAM least-privilege roles,
CloudWatch Logs/Alarms/Dashboards + SNS, ACM (TLS termination).
```

### Prerequisites

***

Before starting, ensure you have:

* Terraform >= 1.14
* Java Development Kit (JDK 17 or higher) and Maven 3.6+ installed locally
* A Spring Boot JAR file
* AWS provider ~> 5.0
* AWS account/credentials with sufficient permissions
* SSM Agent installed - Pre-installed on many AWS-provided AMIs, including Amazon Linux 2, Amazon Linux 2023, Ubuntu
  20.04+, and Windows Server 2016+
* IAM Role with ```AmazonSSMManagedInstanceCore``` attached
* AWS CLI configured with credentials
* AWS SSM Session Manager Plugin installed locally on your desktop or laptop
* Git installed
* This project, I have used pgAdmin for Postgres. RDS instance with username and password to connect via any GUI DB
  client
* Basic understanding of REST APIs and databases

### Implementation

***

**Step 1: Terraform Outputs**

After successful deployment, the following outputs will be available:

- ```iam_role_terraform_execution_arn``` — IAM role terraform execution ARN
- ```ec2_instance_ids``` — Instance IDs of EC2 server (use these to start an SSM session)
- ```ec2_private_ips``` — Private IP addresses of the EC2 instance (s)
- ```alb_dns_name``` — DNS name of the Application Load Balancer
- ```rds_endpoint``` — Connection endpoint (`host:port`) for the RDS primary
- ```rds_db_name``` — DB name of the RDS PostgreSQL
- ```rds_db_username``` — DB username of the RDS PostgreSQL
- ```db_credentials_secret_name``` — Name of the Secrets Manager secret holding the RDS master credentials
- ```ssm_connect_commands``` — AWS CLI commands to open a Session Manager shell on each instance
- ```ssm_port_forward_commands``` — AWS CLI commands to open an SSM port-forwarding session from your laptop to the RDS
  primary, via each private EC2 host

![1-Ouputs.png](Screenshot%20verification/1-Ouputs.png)

**Step 2: Deployment Workflow**

- ```checkov.yml``` — Automated security scanning framework using Checkov to detect Terraform misconfigurations at both
  repository and pull request (PR) levels
- ```deploy_infra.yml``` — Terraform workflow to provision infrastructure
- ```deploy_app.yml``` — Terraform workflow to deploy JAR Java Spring Boot application from S3 to EC2

### Verification

***

You can check the full documentation for **technical specifications** in ```Documentation``` directory and all
screenshot in ```Screenshot verification```.

- **Connect EC2 to RDS**

Applications in the same VPC connect normally using the RDS endpoint. The VPC's internal DNS resolves the endpoint to
the private IP address.

```
# From an EC2 instance in the VPC
psql -h myapp-rds-postgres.conyo2aki51n.us-east-1.rds.amazonaws.com -U app_admin -d springbootcrud -p 5432
```

- **Run & Test Application**

![2-App runnin.png](Screenshot%20verification/2-App%20runnin.png)

- **Test the Application using Bruno or Postman with ALB DNS**

* Health Check: ```GET http://alb-dns/notes/health```
* Create Note: ```POST http://alb-dns/notes```
* Create multi Note: ```POST http://alb-dns/notes/save-all```
* Get All Note and/or filter by title: ```GET http://alb-dns/notes```
* Get Note by ID: ```GET http://alb-dns/notes/{id}```
* Update Note: ```PUT http://alb-dns/notes```
* Delete Note: ```DELETE http://alb-dns/notes/{id}```

### Troubleshooting

***
Problem : **Circular module dependency** — `rds instance` → needs → `cloudwatch log group name` → needs →
`rds identifier` → needs → `rds instance`

### Summary

***

We have successfully:

* Created a complete Spring Boot CRUD application with REST endpoints
* Configured the application with externalized database properties
* Built the application into a deployable JAR file
* Set up AWS infrastructure including:
    * Infrastructure as Code with Terraform.
    * Networking — VPC with two AZs, public/private/database subnets.
    * S3 bucket — Stores our application JAR file and for access logs.
    * Gateway Endpoint for S3.
    * VPC endpoints — SSM, EC2 messages, and SSM messages.
    * EC2 instances backend App Tier in private subnet with SSM agent installed (which has NAT Gateway
      to access internet). Access via SSM only — no bastion host, no SSH inbound rule, no public IP on
      the app or DB tiers.
    * RDS PostgreSQL database with proper configuration.
    * Secret Manager — to securely store, rotate, and manage database credentials.
    * KMS — KMS key for RDS, Secrets Manger, CloudWatch encryption.
    * EC2 instance for application hosting.
    * ALB in public subnet for distributing incoming traffic.
    * Security — Security Groups, NACLs, VPC endpoints, KMS for encryption, IAM roles with the least privilege.
    * IAM roles for secure access.
    * CloudWatch — Log group for ALB, App tier and RDS database.
    * SNS — Shared KMS-encrypted SNS topic + email subscription.
    * CI/CD Pipeline for automatic deployments.
* Deployed the application to EC2
* Tested all CRUD operations

**Next Steps for Production**

1. Multi-AZ deployment (3 AZs) for high availability
2. Auto Scaling: Configure auto-scaling groups for EC2
3. Add Authentication: Implement JWT or OAuth2 security
4. Database Backup: Enable automated RDS backups and multi-AZ
5. Rate Limiting: Implement API rate limiting
6. Database Optimization: Add indexes and optimize queries

**Key Takeaways**

* Always use environment variables for sensitive configuration
* Implement proper security groups for network isolation
* Use IAM roles instead of hardcoding AWS credentials
* Monitor application logs and database connections
* Keep your AWS resources up to date with latest patches
* Regular backups are essential for data safety
* Test your application thoroughly before production
