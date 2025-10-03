# AWS EC2 Infrastructure with Terraform

This repository contains Infrastructure as Code to provision an Amazon EC2 instance with restricted SSH access. A Makefile is provided to streamline common tasks across Terraform, Ansible, and SSH.

## Prerequisites

- Terraform (>= 1.5)
- AWS account with credentials configured locally
  - Either via AWS CLI profiles (`aws configure`) or environment variables:
    - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`
  - Optional: `AWS_PROFILE` if using named profiles
- SSH key pair available locally (for connecting to the instance)
- Make (to run the provided Makefile targets)
- Optional for app deployment: Ansible (`ansible-playbook`)
- Optional for local app: Node.js and npm (for running locally)

## Quick Start

1) Clone and enter the project:
   ```bash
   git clone <your-repo-url>
   cd <project-directory>
   ```

2) Configure AWS credentials (choose one):
   - Using profile:
     ```bash
     aws configure
     export AWS_PROFILE=<your-profile>
     ```
   - Using environment variables:
     ```bash
     export AWS_ACCESS_KEY_ID=...
     export AWS_SECRET_ACCESS_KEY=...
     export AWS_DEFAULT_REGION=...
     ```

3) Initialize Terraform and create variables file:
   ```bash
   make tf-init
   make tf-vars
   ```
   Then edit `infra/terraform/terraform.tfvars` to match your environment.

4) Validate, plan, and apply the infrastructure:
   ```bash
   make tf-validate
   make tf-plan
   make tf-apply
   ```
   Inspect outputs:
   ```bash
   make tf-outputs
   make ip
   ```

5) Wait for SSH to become available:
   ```bash
   make wait-ssh
   ```

6) Generate an Ansible inventory (auto-uses Terraform output IP if available):
   ```bash
   make inventory
   ```
   You can override the IP or key if needed:
   ```bash
   SERVER_IP=<PUBLIC_IP> PRIVATE_KEY=~/.ssh/your_key make inventory
   ```

7) Deploy or update the application (optional):
   - By default, the repo’s origin URL is used. To override:
     ```bash
     REPO_URL=<git repo url> make deploy
     ```

8) SSH into the instance:
   ```bash
   make ssh
   ```

## Configuration and Overrides

You can override the following variables when invoking `make`:
- `TF_DIR` — Terraform working directory (default: `infra/terraform`)
- `SERVER_IP` — Public IP of the instance (auto-detected from Terraform outputs if available)
- `INVENTORY` — Path to Ansible inventory (default: `ansible/inventory.ini`)
- `PRIVATE_KEY` — SSH private key for connecting to the instance (default: `~/.ssh/id_rsa`)
- `APP_PLAYBOOK` — Ansible playbook to deploy the app
- `APP_TAGS` — Ansible tags used during deployment
- `WAIT_SSH_ATTEMPTS`, `WAIT_SSH_DELAY` — Controls for SSH readiness checks

Examples:

- End-to-end: provision, deploy, and connect
  ```bash
  # Configure credentials (choose your method)
  aws configure
  export AWS_PROFILE=dev

  # Terraform workflow
  make tf-init
  make tf-vars
  # Edit variables file as needed
  make tf-validate
  make tf-plan
  make tf-apply
  make tf-outputs
  make ip

  # Wait for SSH and generate inventory
  make wait-ssh
  make inventory

  # Deploy app (override repo if desired)
  REPO_URL=https://github.com/you/your-app.git make deploy

  # SSH into the instance
  make ssh
  ```

- Override IP and SSH key explicitly
  ```bash
  SERVER_IP=203.0.113.10 PRIVATE_KEY=~/.ssh/my_key make inventory
  SERVER_IP=203.0.113.10 make ssh
  ```

- Provision only and print the public IP
  ```bash
  make tf-init
  make tf-validate
  make tf-plan
  make tf-apply
  make ip
  ```

- Teardown and cleanup
  ```bash
  make tf-destroy
  make clean
  ```

- Optional: run the app locally
  ```bash
  make run-local
  ```
