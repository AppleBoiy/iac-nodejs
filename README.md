# AWS EC2 + Ansible + GitHub Actions: Node.js CI/CD (demo-terraform)

This project provisions an Ubuntu EC2 instance with Terraform, configures it with Ansible, and deploys a simple Node.js service. The app is served on port 80 via Nginx (reverse proxy to Node on port 3000). A GitHub Actions workflow demonstrates automated deployments using Ansible over SSH.

## Prerequisites
- Terraform >= 1.5
- AWS CLI configured (via environment variables, shared credentials, or SSO profile)
- An SSH keypair on your machine (e.g., `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`)
- Ansible installed locally (for manual runs), or use the provided GitHub Actions workflow
- A GitHub repository to host this code

## Infrastructure (Terraform)
This configuration creates a single Ubuntu EC2 instance with a public IP and SSH access using your existing SSH key. It uses your AWS default VPC and a default subnet. Security group allows SSH (22) from your CIDR and HTTP (80) from anywhere.

### Configure AWS credentials
Use either environment variables or a profile. Example with a profile:

## Configure AWS credentials
Use either environment variables or a profile. Example with a profile:

```bash
export AWS_PROFILE={{AWS_PROFILE}}
aws sts get-caller-identity
```

If using access keys, set them as environment variables instead of pasting them in files:

```bash
export AWS_ACCESS_KEY_ID={{AWS_ACCESS_KEY_ID}}
export AWS_SECRET_ACCESS_KEY={{AWS_SECRET_ACCESS_KEY}}
export AWS_DEFAULT_REGION=us-east-1
```

## Setup variables
Copy the example and edit as needed:

```bash
cp terraform.tfvars.example terraform.tfvars
```

For better security, restrict SSH to your IP. You can automatically capture it:

```bash
MY_IP=$(curl -s https://checkip.amazonaws.com)
# Then either edit terraform.tfvars or pass it on the CLI when planning/applying:
# -var "allowed_ssh_cidr=${MY_IP}/32"
```

## Deploy
Initialize and deploy:

```bash
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

## Outputs and SSH
After apply, Terraform prints outputs including the public IP and a ready-to-copy SSH command. For example:

```bash
terraform output -raw instance_public_ip
terraform output -raw ssh_command
```

Then SSH to the instance (Ubuntu images use the `ubuntu` user by default):

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<PUBLIC_IP>
```

## Destroy
When you're done, tear down the resources:

```bash
terraform destroy
```

## Notes
- AMI is the latest Ubuntu 24.04 LTS for your chosen region.
- Resources are tagged via the `tags` variable; customize as you wish.
- The configuration uses the default VPC and one of its default subnets.
