#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker/docker-compose.yml"
ENV_FILE="${ROOT_DIR}/docker/.env"
BACKUP_DIR="${ROOT_DIR}/backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/twenty_${TIMESTAMP}.sql"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Error: ${ENV_FILE} not found. Copy docker/.env.example to docker/.env and configure it." >&2
  exit 1
fi

if ! docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" ps --status running --services db 2>/dev/null | grep -q '^db$'; then
  echo "Error: db service is not running. Start the stack first:" >&2
  echo "  docker compose -f docker/docker-compose.yml --env-file docker/.env up -d" >&2
  exit 1
fi

mkdir -p "${BACKUP_DIR}"

# shellcheck source=/dev/null
source "${ENV_FILE}"

PG_USER="${PG_DATABASE_USER:-postgres}"
PG_DB="${PG_DATABASE_NAME:-default}"

echo "Backing up database '${PG_DB}' to ${BACKUP_FILE}..."

docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" exec -T db \
  pg_dump -U "${PG_USER}" -d "${PG_DB}" --no-owner --no-acl \
  > "${BACKUP_FILE}"

echo "Backup complete: ${BACKUP_FILE}"
