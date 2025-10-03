# Makefile: Helper commands for Terraform, Ansible deployment, SSH, and local Node app

SHELL := /bin/bash

TF ?= terraform
ANSIBLE_PLAYBOOK ?= ansible-playbook

# Inventory file path for Ansible
INVENTORY ?= ansible/inventory.ini

# Defaults (can be overridden): SSH key and repo URL
PRIVATE_KEY ?= $(HOME)/.ssh/id_rsa
REPO_URL ?= $(shell git config --get remote.origin.url)

# Playbook and tags for app deployment
APP_PLAYBOOK ?= node_service.yml
APP_TAGS ?= app

# Attempt to read EC2 IP from Terraform outputs; can be overridden as SERVER_IP
SERVER_IP ?= $(shell $(TF) output -raw instance_public_ip 2>/dev/null || true)

# Wait-for-SSH settings
WAIT_SSH_ATTEMPTS ?= 30
WAIT_SSH_DELAY ?= 5

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_.-]+:.*?## ' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# -----------------------
# Terraform commands
# -----------------------
.PHONY: tf-init
tf-init: ## Terraform init
	$(TF) init

.PHONY: tf-validate
tf-validate: ## Terraform validate
	$(TF) validate

.PHONY: tf-plan
tf-plan: ## Terraform plan (outputs tfplan)
	$(TF) plan -out=tfplan

.PHONY: tf-apply
tf-apply: ## Terraform apply using plan (creates/updates infra)
	@if [ ! -f tfplan ]; then echo "tfplan not found; running plan first..."; $(TF) plan -out=tfplan; fi
	$(TF) apply tfplan

.PHONY: tf-destroy
tf-destroy: ## Terraform destroy (tear down infra)
	$(TF) destroy

.PHONY: tf-outputs
tf-outputs: ## Show Terraform outputs
	$(TF) output

.PHONY: ip
ip: ## Print instance public IP (from Terraform outputs)
	@$(TF) output -raw instance_public_ip

# -----------------------
# Ansible deployment
# -----------------------
.PHONY: inventory
inventory: ## Generate ansible/inventory.ini from SERVER_IP (or Terraform outputs)
	@mkdir -p $$(dirname "$(INVENTORY)")
	@if [ -z "$(SERVER_IP)" ]; then \
		echo "SERVER_IP not set and not found via Terraform outputs."; \
		echo "Set SERVER_IP=<PUBLIC_IP> or run 'make tf-apply' first."; \
		exit 1; \
	fi
	@echo "[all]" > "$(INVENTORY)"
	@if [ -n "$$SSH_AUTH_SOCK" ]; then \
		echo "server ansible_host=$(SERVER_IP) ansible_user=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> "$(INVENTORY)"; \
	else \
		echo "server ansible_host=$(SERVER_IP) ansible_user=ubuntu ansible_ssh_private_key_file=$(PRIVATE_KEY)" >> "$(INVENTORY)"; \
	fi
	@echo "Wrote $(INVENTORY) with SERVER_IP=$(SERVER_IP)"

.PHONY: deploy
deploy: inventory ## Deploy/Update the Node app via Ansible (role: app)
	@if [ -z "$(REPO_URL)" ]; then \
		echo "REPO_URL not detected. Override with REPO_URL=<git repo url>"; \
		exit 1; \
	fi
	$(ANSIBLE_PLAYBOOK) -i "$(INVENTORY)" "$(APP_PLAYBOOK)" --tags "$(APP_TAGS)" -e app_repo_url="$(REPO_URL)"

.PHONY: wait-ssh
wait-ssh: ## Wait until SSH is reachable on SERVER_IP
	@IP="$(SERVER_IP)"; \
	if [ -z "$$IP" ]; then IP="$$( $(TF) output -raw instance_public_ip 2>/dev/null || true )"; fi; \
	if [ -z "$$IP" ]; then echo "Instance IP unknown. Set SERVER_IP or run 'make tf-apply'."; exit 1; fi; \
	echo "Waiting for SSH on $$IP:22 ..."; \
	for i in $$(seq 1 $(WAIT_SSH_ATTEMPTS)); do \
	  if ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=5 "ubuntu@$$IP" 'exit 0' 2>/dev/null; then \
	    echo "SSH is reachable."; exit 0; \
	  fi; \
	  echo "Attempt $$i/$(WAIT_SSH_ATTEMPTS): SSH not reachable yet; retrying in $(WAIT_SSH_DELAY)s ..."; \
	  sleep $(WAIT_SSH_DELAY); \
	done; \
	echo "ERROR: SSH not reachable on $$IP:22"; exit 1

# -----------------------
# SSH convenience
# -----------------------
.PHONY: ssh
ssh: ## SSH into the instance using PRIVATE_KEY (auto-detect IP if possible)
	@IP="$(SERVER_IP)"; \
	if [ -z "$$IP" ]; then IP="$$( $(TF) output -raw instance_public_ip 2>/dev/null || true )"; fi; \
	if [ -z "$$IP" ]; then echo "Instance IP unknown. Set SERVER_IP or run 'make tf-apply'."; exit 1; fi; \
	ssh -i "$(PRIVATE_KEY)" ubuntu@$$IP

# -----------------------
# Local Node app (optional)
# -----------------------
.PHONY: run-local
run-local: ## Run the Node app locally (on port 3000)
	cd app && npm install && npm start

.PHONY: build-local
build-local: ## Build the Node app (if a build script exists)
	cd app && npm install && npm run build

# -----------------------
# Utilities
# -----------------------
.PHONY: clean
clean: ## Clean generated files (plan and inventory)
	@rm -f tfplan plan.out
	@rm -f "$(INVENTORY)"
