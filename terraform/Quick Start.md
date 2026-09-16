## Deploy Spring Boot CRUD → EC2 + RDS PostgreSQL (Terraform)

**Objective**: a public ALB in front of a Spring Boot application tier (EC2, private subnets), backed by an isolated
RDS PostgreSQL Multi-AZ database, across two Availability Zones (`us-east-1a`, `us-east-1b`).

## Architecture overview

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

![spring-boot-rds-crud.png](../spring-boot-rds-crud.png)

**Traffic Flow**

1. User requests → ALB (HTTPS / TLS 1.2/1.3)
2. ALB → App tier Server
3. App tier Server → RDS (Private IP / TLS 1.2+)
4. Response → ALB → User

### Quick Start

***

- **Step 1 — Fork and clone**
  ```
  $ git clone https://github.com/darvin-rakotomalala/deploy-spring-boot-rds-crud
  $ cd deploy-spring-boot-rds-crud/terraform
  ```

- **Step 2 — Configure Terraform**<br>
  Edit ```deploy-spring-boot-rds-crud/terraform/terraform.tfvars``` to match your target region and preferences. No
  secrets go here — just region, default tags and adjust for your environment

- **Step 3 — Deploy infrastructure**

  ```
  $ cd deploy-spring-boot-rds-crud/terraform
  $ terraform init
  $ terraform fmt -recursive
  $ terraform validate
  $ terraform plan -var-file="terraform.tfvars" -no-color -out=TFplan.JSON
  $ terraform apply -var-file="terraform.tfvars" -auto-approve
  ```

- **Migration to remote backend**

    - Add or activate backend configuration : ```backend.tf```
    - Reinitialize to migrate state: ```terraform init -migrate-state```

### Cleanup

***

To destroy all resources, run ```terraform destroy -var-file="terraform.tfvars" -auto-approve```
