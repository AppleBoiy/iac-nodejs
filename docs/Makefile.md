# Makefile Manual

This Makefile streamlines common tasks for provisioning infrastructure, deploying the Node.js app with Ansible, SSH access, and local app development.

## Prerequisites
- make
- Terraform (TF variable defaults to terraform)
- Ansible (ANSIBLE_PLAYBOOK variable defaults to ansible-playbook)
- SSH access to the provisioned instance (key on your machine)

## Configurable Variables
Override any variable by prefixing the command, e.g., `SERVER_IP=1.2.3.4 make deploy`.

- SERVER_IP: Public IP of your EC2 instance. Auto-detected from Terraform outputs if available.
- PRIVATE_KEY: Path to your SSH private key (default: ~/.ssh/id_rsa).
- REPO_URL: Git repo URL; auto-detected from `git remote origin` if set.
- INVENTORY: Path to generated Ansible inventory file (default: ansible/inventory.ini).
- TF: Terraform binary (default: terraform).
- ANSIBLE_PLAYBOOK: Ansible binary (default: ansible-playbook).
- APP_PLAYBOOK: Ansible playbook file (default: node_service.yml).
- APP_TAGS: Tags to run (default: app).

## Targets
- help: Show available targets.
- tf-init: Terraform init.
- tf-validate: Terraform validate.
- tf-plan: Terraform plan (writes tfplan).
- tf-apply: Terraform apply using tfplan (creates/updates infra).
- tf-outputs: Show all Terraform outputs.
- tf-destroy: Destroy infrastructure.
- ip: Print instance public IP from Terraform outputs.
- inventory: Generate Ansible inventory from SERVER_IP (or Terraform outputs).
- deploy: Deploy/update Node app via Ansible (role: app). Requires REPO_URL.
- ssh: SSH into instance using PRIVATE_KEY and detected SERVER_IP.
- run-local: Run the Node app locally (port 3000).
- build-local: Build the Node app locally (if a build script exists).
- clean: Remove generated tfplan and inventory.
