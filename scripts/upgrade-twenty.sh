#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker/docker-compose.yml"
ENV_FILE="${ROOT_DIR}/docker/.env"
BACKUP_SCRIPT="${ROOT_DIR}/scripts/backup-db.sh"

usage() {
  echo "Usage: $0 <new-tag>" >&2
  echo "Example: $0 v2.15.0" >&2
  exit 1
}

[[ $# -eq 1 ]] || usage

NEW_TAG="$1"

if [[ ! "${NEW_TAG}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: tag must look like v2.14.0 (got: ${NEW_TAG})" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Error: ${ENV_FILE} not found. Copy docker/.env.example to docker/.env and configure it." >&2
  exit 1
fi

CURRENT_TAG="$(grep -E '^TAG=' "${ENV_FILE}" | cut -d= -f2- | tr -d '"' | tr -d "'")"
echo "Upgrading Twenty: ${CURRENT_TAG:-unknown} → ${NEW_TAG}"

echo ""
echo "Step 1/5: Creating database backup..."
"${BACKUP_SCRIPT}"

echo ""
echo "Step 2/5: Updating TAG in ${ENV_FILE}..."
if grep -qE '^TAG=' "${ENV_FILE}"; then
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/^TAG=.*/TAG=${NEW_TAG}/" "${ENV_FILE}"
  else
    sed -i "s/^TAG=.*/TAG=${NEW_TAG}/" "${ENV_FILE}"
  fi
else
  echo "TAG=${NEW_TAG}" >> "${ENV_FILE}"
fi

echo ""
echo "Step 3/5: Pulling new images..."
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" pull server worker

echo ""
echo "Step 4/5: Restarting services..."
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d

echo ""
echo "Step 5/5: Waiting for health check..."

# shellcheck source=/dev/null
source "${ENV_FILE}"
HEALTH_URL="${SERVER_URL%/}/healthz"

MAX_ATTEMPTS=60
ATTEMPT=0
until curl --fail --silent "${HEALTH_URL}" > /dev/null 2>&1; do
  ATTEMPT=$((ATTEMPT + 1))
  if [[ ${ATTEMPT} -ge ${MAX_ATTEMPTS} ]]; then
    echo "Error: server did not become healthy at ${HEALTH_URL} within $((MAX_ATTEMPTS * 5)) seconds." >&2
    echo "Check logs: docker compose -f docker/docker-compose.yml --env-file docker/.env logs server" >&2
    exit 1
  fi
  echo "  Waiting... (${ATTEMPT}/${MAX_ATTEMPTS})"
  sleep 5
done

echo ""
echo "Upgrade complete: ${NEW_TAG}"
echo ""
echo "Verify migration status:"
echo "  docker compose -f docker/docker-compose.yml --env-file docker/.env exec server yarn command:prod upgrade:status"
echo ""
echo "If issues persist, check failed workspaces:"
echo "  docker compose -f docker/docker-compose.yml --env-file docker/.env exec server yarn command:prod upgrade:status --failed-only"
echo ""
echo "Document this upgrade in docs/upgrades/ (backup filename, smoke test results, changelog notes)."
