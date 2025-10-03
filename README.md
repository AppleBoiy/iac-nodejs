# AWS EC2 Infrastructure with Terraform

This repository contains Infrastructure as Code to provision an Amazon EC2 instance with restricted SSH access. Use the provided Makefile for common operations instead of raw commands.

## Prerequisites

- Terraform (>= 1.5)
- AWS account and credentials configured locally
  - Via AWS CLI profiles (`aws configure`) or environment variables:
    - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`
  - Optional: `AWS_PROFILE` if using named profiles
- SSH key pair available locally if you plan to create or use an EC2 key pair

## Quick Start

1) Clone and enter the project:
- git clone <your-repo-url>
- cd <your-repo-folder>

2) Create and edit variables:
- make tf-vars
- Edit the generated terraform.tfvars to suit your environment. Example:
  - instance_type     = "t3.micro"
  - key_name          = "my-ec2-key"
  - create_key_pair   = true
  - public_key_path   = "~/.ssh/id_rsa.pub"
  - allowed_ssh_cidr  = "<YOUR_IP>/32"

Notes:
- Use an appropriate `instance_type` available in your target region.
- `key_name` is the name of the AWS EC2 key pair.
- Set `create_key_pair = true` to upload your local public key at `public_key_path`.
- If you already have a key pair in AWS and want to use it, set `create_key_pair = false` and ensure `key_name` matches the existing AWS key pair; `public_key_path` can be omitted in that case.
- `allowed_ssh_cidr` should be a restricted CIDR (avoid 0.0.0.0/0).

3) Initialize:
- make tf-init

4) Review the plan:
- make tf-plan

5) Apply to provision:
- make tf-apply

6) Get the instance public IP:
- make ip

7) (Optional) Wait until SSH is reachable:
- make wait-ssh

8) SSH into the instance:
- make ssh
- You can override the key path via PRIVATE_KEY, e.g., PRIVATE_KEY=~/.ssh/id_rsa make ssh

9) (Optional) Deploy the Node app via Ansible:
- Generate inventory from the instance IP: make inventory
- Deploy: make deploy
  - The repository URL is auto-detected from your git remote; override with REPO_URL=<git-url> if needed.

## Configuration

- Use `terraform.tfvars` for infrastructure variables (created by `make tf-vars`).
- Region: set via your AWS config/profile or `AWS_DEFAULT_REGION` environment variable.

Common Make variables you can override per command:
- SERVER_IP: manually set the server IP if outputs are not yet available. Example: SERVER_IP=<PUBLIC_IP> make ssh
- PRIVATE_KEY: path to your SSH private key for `make ssh`. Example: PRIVATE_KEY=~/.ssh/id_rsa make ssh
- REPO_URL: Git repository used by the deploy step. Example: REPO_URL=https://github.com/user/repo.git make deploy

## Clean Up

- Tear down all resources: make tf-destroy
- Remove generated files (plan, inventory): make clean

## Troubleshooting

- Credentials/Region issues:
  - Ensure `AWS_PROFILE` (if used) is set, or `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` are exported.
- Key pair conflicts:
  - If `create_key_pair = true` and a key pair with the same `key_name` already exists in AWS, adjust `key_name` or delete/rename the existing key pair.
- SSH access denied:
  - Confirm `allowed_ssh_cidr` includes your current public IP and that you are using the correct private key file and username for the AMI.
- Repo URL for deploy:
  - If auto-detection fails, pass `REPO_URL=<git-url>` to `make deploy`.

## Security Best Practices

- Use a restrictive `allowed_ssh_cidr` (prefer /32 for your IP).
- Rotate SSH keys periodically.
- Keep your AWS credentials secure and avoid committing them to version control.

## Using Terraform

- The Makefile wraps Terraform commands for convenience (init, plan, apply, destroy, outputs).
