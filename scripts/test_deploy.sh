#!/usr/bin/env bash
set -euo pipefail

# test_deploy.sh
# Optionally deploys the app and verifies the deployment by checking the HTTP response.
#
# Usage:
#   scripts/test_deploy.sh [--deploy] [--ip <SERVER_IP>] [--timeout <seconds>] [--interval <seconds>]
#
# Env vars:
#   SERVER_IP   - public IP of the server (falls back to terraform output if not set)
#   PRIVATE_KEY - SSH private key path for deployment (default: ~/.ssh/id_rsa)
#   REPO_URL    - repository URL to deploy (auto-detected from git remote if possible)
#
# Examples:
#   scripts/test_deploy.sh --deploy
#   scripts/test_deploy.sh --ip 203.0.113.10 --timeout 180 --interval 5

TIMEOUT="${TIMEOUT:-120}"
INTERVAL="${INTERVAL:-5}"
DO_DEPLOY=0

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --deploy               Run deployment before testing (via 'make deploy' if available)
  --ip <SERVER_IP>       Target server public IP (defaults to terraform output)
  --timeout <seconds>    Total time to wait for success (default: ${TIMEOUT})
  --interval <seconds>   Time between probes (default: ${INTERVAL})
  -h, --help             Show this help

Environment:
  SERVER_IP    Public IP of the server (overrides --ip)
  PRIVATE_KEY  SSH private key (default: \$HOME/.ssh/id_rsa)
  REPO_URL     Git repository URL to deploy (auto-detected if possible)
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --deploy) DO_DEPLOY=1; shift ;;
    --ip) SERVER_IP="${2:-}"; shift 2 ;;
    --timeout) TIMEOUT="${2:-}"; shift 2 ;;
    --interval) INTERVAL="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Determine server IP
if [[ -z "${SERVER_IP:-}" ]]; then
  if command -v terraform >/dev/null 2>&1; then
    SERVER_IP="$(terraform output -raw instance_public_ip 2>/dev/null || true)"
  fi
fi

if [[ -z "${SERVER_IP:-}" ]]; then
  echo "ERROR: SERVER_IP is not set and could not be determined from terraform outputs."
  echo "Provide --ip <SERVER_IP> or set SERVER_IP env."
  exit 2
fi

echo "Target SERVER_IP: ${SERVER_IP}"

# Optional deploy step
if [[ "$DO_DEPLOY" -eq 1 ]]; then
  REPO_URL="${REPO_URL:-$(git config --get remote.origin.url 2>/dev/null || true)}"
  PRIVATE_KEY="${PRIVATE_KEY:-$HOME/.ssh/id_rsa}"

  if [[ -z "$REPO_URL" ]]; then
    echo "WARN: REPO_URL not auto-detected; consider setting REPO_URL explicitly."
  fi

  if command -v make >/dev/null 2>&1; then
    echo "Deploying via 'make deploy'..."
    SERVER_IP="$SERVER_IP" PRIVATE_KEY="$PRIVATE_KEY" REPO_URL="$REPO_URL" make deploy
  elif command -v ansible-playbook >/dev/null 2>&1; then
    echo "Deploying via 'ansible-playbook'..."
    INV_FILE="$(mktemp)"
    echo "[all]" > "$INV_FILE"
    echo "server ansible_host=$SERVER_IP ansible_user=ubuntu ansible_ssh_private_key_file=$PRIVATE_KEY" >> "$INV_FILE"
    PLAYBOOK="ansible/playbooks/node_service.yml"
    [[ -f "$PLAYBOOK" ]] || PLAYBOOK="node_service.yml"
    ansible-playbook -i "$INV_FILE" "$PLAYBOOK" --tags app -e "app_repo_url=${REPO_URL}"
  else
    echo "ERROR: Neither 'make' nor 'ansible-playbook' found to perform deployment."
    exit 3
  fi
fi

# Probe the service endpoint for expected response
echo "Probing http://${SERVER_IP}/ for 'Hello, new world!' (timeout=${TIMEOUT}s, interval=${INTERVAL}s)..."
deadline=$((SECONDS + TIMEOUT))
rc=1

while (( SECONDS < deadline )); do
  # Capture body and status code in one call
  resp="$(curl -sS --max-time 5 -H 'Accept: text/plain' -w ' HTTP_STATUS:%{http_code}' "http://${SERVER_IP}/" || true)"
  code="$(printf "%s" "$resp" | awk -F'HTTP_STATUS:' '{print $2}')"
  body="$(printf "%s" "$resp" | sed -e 's/ HTTP_STATUS:.*$//')"

  if [[ "$code" == "200" && "$body" == *"Hello, world!"* ]]; then
    echo "SUCCESS: HTTP 200 with expected content."
    rc=0
    break
  fi

  echo "Waiting... (status=${code:-n/a})"
  sleep "$INTERVAL"
done

if [[ "$rc" -ne 0 ]]; then
  echo "ERROR: Deployment verification failed. Expected 'Hello, world!' with HTTP 200 before timeout."
fi

exit "$rc"
