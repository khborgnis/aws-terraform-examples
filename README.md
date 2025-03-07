# Sample AWS Terraform Project

This is a simple **Terraform** project that provisions infrastructure on **AWS**. The project will iterate over a design in short bursts that leads to an application hosted by AWS ECS in containers running in an EC2 Auto Scaling Group of Debian instances, load balanced.

This is not intended as an "ideal" design, just practicing using different features of AWS with terraform.

## Progress

In roughly **one hour of development**, the following AWS resources have been set up using Terraform:

- **VPC**: A custom Virtual Private Cloud (VPC) is created with public and private subnets.
- **RDS Instance**: A basic RDS MySQL instance, placed in private subnet group.

With roughly **two additional hours of development**, the following AWS resources have been set up using Terraform:

- **EC2**: An ec2 instance running with ECS init and docker installed on it
- **Security Group**: A basic security group allowing inbound SSH and HTTP(8080) traffic.

With roughly **two additional hours of development**, the following AWS resources have been set up using Terraform:

- **EC2**: A launch template built from the previous ec2 instance configuration, as well as an auto scaling group
- **ECS**: An ecs service has been configured, with a service and task
- **Security Group**: A basic security group allowing inbound SSH and HTTP(8080) traffic.

## Structure

```plaintext
.
├── providers.tf      # terraform and providers blocks defining required providers
├── data.tf           # data objects useful for referencing in resources
├── rds.tf            # Configuration defining the RDS configurations
├── vpc.tf            # Basic setup of the VPC and subnets
└── README.md         # This file
```

## Requirements

- [Terraform](https://www.terraform.io/downloads.html) (v1.0+ recommended)
- AWS credentials configured (via AWS CLI or environment variables)

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/aws-terraform-sample.git
cd aws-terraform-sample
```

### 2. Initialize the Terraform configuration

Run the following command to initialize the Terraform project:

```bash
terraform init
```

This will install the necessary Terraform providers (AWS in this case) and prepare the working directory.

### 3. Review the planned execution

Before applying changes, run `terraform plan` to see the resources Terraform will create:

```bash
terraform plan -var "personal_ip=$(curl -s ipinfo.io/ip)"
```

### 4. Apply the Terraform configuration

Once you're happy with the plan, apply the configuration:

```bash
terraform apply -var "personal_ip=$(curl -s ipinfo.io/ip)"
```

Confirm the action when prompted by typing `yes`.

### 5. Retrieve output

Once the resources are created, Terraform will output the public IP of the EC2 instance. You can find this in the `outputs.tf` file or simply view the output after running `terraform apply`.

## Future Steps

After an hour of development, the infrastructure setup is minimal. You can continue expanding by:

- Adding EC2 instances.
- Configuring additional services like IAM roles, Lambda, - and S3 buckets.
- Improving security with better network segregation, IAM policies, and monitoring.
- Creating more advanced automation with remote state, workspaces, or CI/CD integration.

## Cleanup

To destroy the infrastructure and avoid ongoing charges, run the following command:

```bash
terraform destroy
```

This will remove all the resources defined in the configuration.

Feel free to copy this directly! Let me know if you need any other modifications.