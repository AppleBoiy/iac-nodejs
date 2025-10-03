# GitHub Configuration Manual (CI/CD Deployment)

This guide explains how to configure your GitHub repository to deploy the Node.js service to your server using GitHub Actions.

## Overview
- A workflow runs on GitHub-hosted runners and connects to your server over SSH.
- It executes an Ansible playbook to deploy/update the application.
- You control the target server and credentials via repository Secrets.

## Prerequisites
- Your code is hosted in a GitHub repository.
- The server is reachable over the internet (port 22 open to your IP and port 80 open to the world).
- An SSH key that can access the server with the `ubuntu` user.

## 1) Add Repository Secrets
- SECRET: SERVER_IP — Public IP of the server
- SECRET: SSH_PRIVATE_KEY — Private key with access for the `ubuntu` user

## 2) Configure Workflow Triggers
Set triggers as needed (e.g., push to main, manual dispatch).

## 3) Repository Access for Cloning
Use a public repository or set up a read-only Deploy Key/token for private repositories.

## 4) Permissions and Settings
Allow GitHub Actions in repository settings; default GITHUB_TOKEN permissions are sufficient.

## 5) Running the Deployment
Push or manually trigger the workflow from the Actions tab.

## 6) Verifying Deployment
Check http://<SERVER_IP>/ returns “Hello, world!”.

## 7) Troubleshooting

### SSH timeout (connect to host <ip> port 22: Connection timed out)
- Ensure your server’s inbound rules allow SSH from GitHub Actions runners. For practice, using a permissive rule on port 22 is acceptable; otherwise, allow the runner IP ranges.
- Confirm the instance is running and has a public IP.
- Verify no host firewall (e.g., ufw) is blocking port 22.
- Make sure the SSH key in repository secrets matches an authorized key on the server for the `ubuntu` user.
- The workflow includes a “Wait for SSH” step with retries; if it still fails, verify connectivity from your network or a cloud shell to isolate the issue.

### Permission denied (publickey)
- The private key in secrets must correspond to a public key on the server under `~ubuntu/.ssh/authorized_keys`.
- Ensure the key has no passphrase (or adjust the workflow to handle it).

### Clone failures
- For private repos, provide Deploy Key/token and use the matching clone URL (SSH or HTTPS).

## 8) Security Best Practices
Rotate secrets regularly, restrict SSH where possible, and use least-privileged access for deployment keys.
In your GitHub repository:
- Go to Settings → Secrets and variables → Actions → New repository secret.

Add the following:
- SECRET: SERVER_IP
  - Value: The server’s public IP (e.g., from your infrastructure output).
- SECRET: SSH_PRIVATE_KEY
  - Value: The contents of the private key that can SSH to your server as `ubuntu`.
  - Ensure the key has no passphrase or adjust the workflow to support a passphrase.

Notes:
- Keep the key read-only and dedicated for this purpose.
- Do not commit keys to the repository.

## 2) Configure Workflow Triggers
A standard deployment workflow can:
- Trigger on pushes to the main branch.
- Allow manual runs via the “Run workflow” button.

You can change branches or add tags as needed by editing the workflow’s `on:` section.

## 3) Repository Access for Cloning on the Server
The deployment process clones the repository directly on the server. You have two options:
- Public repository: No extra configuration required.
- Private repository: You must provide access for the server to clone.
  - Option A (recommended for simplicity): Temporarily make the repository public during practice.
  - Option B: Use a read-only Deploy Key (server-side SSH keypair). Add the public key as a Deploy Key in GitHub; place the private key on the server for the deployment user. Adjust your automation to use the SSH URL (git@github.com:owner/repo.git).
  - Option C: Use an HTTPS URL with a token; ensure you inject the token securely (avoid echoing tokens in logs).

## 4) Permissions and Settings
- Actions → General:
  - Allow GitHub Actions to run for this repository.
  - Default GITHUB_TOKEN permissions are sufficient for this workflow.
- Branch protection (optional): Protect main and require PRs; deployment still triggers once changes are merged.

## 5) Running the Deployment
- Push to the configured branch (e.g., main), or
- Go to Actions → Select the deployment workflow → Run workflow.

The workflow will:
- Checkout code.
- Install Ansible.
- Load your SSH key via the agent.
- Add the server to known_hosts.
- Create a temporary inventory file.
- Run the Ansible playbook to deploy the app.

## 6) Verifying Deployment
- Visit http://<SERVER_IP>/ in a browser or use curl:
  ```
  curl -i http://<SERVER_IP>/
  ```
- You should see “Hello, world!” with HTTP 200.

## 7) Troubleshooting
- Permission denied (publickey):
  - The SSH key in Secrets must match a key authorized on the server for the `ubuntu` user.
  - Verify the server allows your connection (ingress on port 22 from your IP).
- Host unreachable:
  - Check server is running and has a public IP.
  - Confirm firewall/security group rules.
- Repository clone fails:
  - Ensure the repository is public, or configure credentials (Deploy Key or token) and use a matching clone URL.
- Ansible apt failures:
  - Temporary apt lock issues can occur; re-run the workflow.
- Service not reachable on port 80:
  - Ensure the web server proxy is running and the application service is active.
  - Validate that security groups allow inbound HTTP (80).

## 8) Security Best Practices
- Rotate SSH keys and repository secrets regularly.
- Limit SSH (22) ingress to your IP address.
- Use a dedicated Deploy Key with read-only access for private repos.
- Avoid printing secrets (tokens/keys) in logs.

## 9) Customizations
- Change the trigger branches or add tag-based deployments.
- Add environment protections (e.g., approvals) under Environments if desired.
- Extend the workflow to handle multi-environment deployments (e.g., staging/production) with different secrets.
