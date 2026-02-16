# Terraform Project

This repository contains Terraform modules and root configuration to provision a simple web application infrastructure on AWS (VPC, public/private subnets, ALB, Auto Scaling Group, S3, Security Groups, etc.).

**Prerequisites**
- Terraform 1.0+ installed
- AWS CLI configured with appropriate credentials (or use environment variables)
- An ACM certificate ARN for HTTPS (if using HTTPS listener)

**How to Use / Deployment Steps**
1. Review and set variables in `variables.tf` or provide a `terraform.tfvars` file with required values (VPC CIDR, AZs, AMI ID, instance type, certificate ARN, subnet lists, etc.).
2. Initialize Terraform:
   - `terraform init`
3. Validate configuration (optional):
   - `terraform validate`
4. Apply the plan:
   - `terraform apply "plan.tfplan"`
5. When finished, destroy resources to avoid charges:
   - `terraform destroy`

**Architecture Decisions**
- VPC with two public and two private subnets across two Availability Zones for high availability.
- Application Load Balancer (ALB) placed in public subnets to terminate TLS and route traffic.
- ALB configured with both HTTP (redirects to HTTPS) and HTTPS listeners. HTTPS requires an ACM certificate ARN passed via `certificate_arn` variable.
- EC2 instances launched in private subnets inside an Auto Scaling Group (ASG) using a `launch_template`.
- NAT Gateway in public subnet used by private instances for outbound internet access.
- S3 used for object storage; the module contains a public-access block to enforce private buckets by default.

  <img width="661" height="481" alt="Terraform Architecture Diagram" src="https://github.com/user-attachments/assets/976745ce-9fa4-4293-a43e-abefa8e33e36" />


**Cost Estimate (High-level)**
- ALB: hourly + LCU charges (depends on traffic pattern)
- NAT Gateway: per hour + data processed (can be significant for heavy egress)
- EC2: depends on chosen instance type, count (ASG min/desired/max)
- EBS volumes: per GB-month
- S3: storage + requests + data transfer

To reduce cost:
- Use smaller instance types or spot instances for non-critical workloads
- Minimize NAT Gateway egress by using S3 VPC endpoints where appropriate
- Set sensible ASG min/max and scale-to-zero where possible for dev environments

**Security Measures**
- ALB placed in public subnets with security groups allowing only required ports (80/443).
- Application instances in private subnets without public IPs; inbound traffic flows via ALB only.
- `aws_s3_bucket_public_access_block` resource applied to S3 to block public policies/ACLs.
- Use IAM roles for EC2 (not in modules by default — consider adding least-privilege role for instance actions).
- Use ACM for TLS termination; do not store certificates in code.
- Store secrets (if any) in AWS Secrets Manager or SSM Parameter Store (secure and encrypted).
- Consider enabling AWS Config, GuardDuty, and CloudTrail for governance and auditing.

**Scaling Strategy**
- ASG configured with `min_size`, `desired_capacity`, and `max_size`. Use target tracking policies (by CPU/Request count) to autoscale.
- ALB provides health checks and distributes traffic across healthy instances.
- For predictable workloads, use scheduled scaling to scale up/down on predictable patterns.
- Use lifecycle and rolling update policies via `max_percent`/`min_healthy_percent` (if using Terraform `aws_autoscaling_policy` or hooks) to ensure safe deployments..
