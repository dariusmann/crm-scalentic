# Docker deployment

Twenty CRM runs via official `twentycrm/twenty` Docker images. This directory contains the compose stack and environment configuration.

## Quick start (local)

1. Copy the environment template:

   ```bash
   cp docker/.env.example docker/.env
   ```

2. Generate secrets and update `docker/.env`:

   ```bash
   openssl rand -base64 32   # use for ENCRYPTION_KEY
   openssl rand -base64 32   # use for PG_DATABASE_PASSWORD (no special characters)
   ```

3. Start the stack from the repo root:

   ```bash
   docker compose -f docker/docker-compose.yml --env-file docker/.env up -d
   ```

4. Open http://localhost:3000 and complete first-time setup.

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TAG` | Yes | Twenty image version (e.g. `v2.14.0`). Pin this; avoid `latest` in production. |
| `SERVER_URL` | Yes | Public URL users use to access Twenty. Must match browser URL (affects OAuth, webhooks). |
| `ENCRYPTION_KEY` | Yes | Encrypts secrets in the database. Generate with `openssl rand -base64 32`. |
| `PG_DATABASE_PASSWORD` | Yes | Postgres password. Use a strong value without special characters. |
| `STORAGE_TYPE` | Yes | `local` for default file storage. Use S3 vars for object storage in production. |
| `FALLBACK_ENCRYPTION_KEY` | No | Previous key during [key rotation](https://docs.twenty.com/developers/self-host/capabilities/setup#encryption-key). |

See [Twenty environment variables](https://docs.twenty.com/developers/self-host/capabilities/setup) for advanced options (email, OAuth, S3).

## Production notes

- Set `SERVER_URL` to your public HTTPS URL (e.g. `https://crm.yourdomain.com`).
- Put a reverse proxy (nginx, Traefik, Caddy) in front of port 3000 with TLS termination.
- Pin `TAG` to a tested release; upgrade via `./scripts/upgrade-twenty.sh`.
- Schedule automated backups (see below).
- Consider S3-compatible storage for file uploads instead of local volumes.

## Backup

From the repo root:

```bash
./scripts/backup-db.sh
```

Backups are written to `backups/twenty_YYYYMMDD_HHMMSS.sql`.

### Automated daily backups (cron)

```bash
0 2 * * * cd /path/to/scalentic-crm && ./scripts/backup-db.sh
```

Store backups off-site and test restores regularly.

## Restore from backup

1. Stop the application services:

   ```bash
   docker compose -f docker/docker-compose.yml --env-file docker/.env stop server worker
   ```

2. Restore the database:

   ```bash
   docker compose -f docker/docker-compose.yml --env-file docker/.env exec -T db \
     psql -U postgres -d default < backups/twenty_YYYYMMDD_HHMMSS.sql
   ```

3. Restart:

   ```bash
   docker compose -f docker/docker-compose.yml --env-file docker/.env up -d
   ```

## Upgrading

```bash
./scripts/upgrade-twenty.sh v2.15.0
```

See [docs/upgrades/README.md](../docs/upgrades/README.md) for the full checklist.

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `server` | `twentycrm/twenty:${TAG}` | 3000 | Web UI and API |
| `worker` | `twentycrm/twenty:${TAG}` | — | Background jobs |
| `db` | `postgres:16` | — | Database |
| `redis` | `redis` | — | Cache and queues |

## Useful commands

```bash
# View logs
docker compose -f docker/docker-compose.yml --env-file docker/.env logs -f server

# Stop stack
docker compose -f docker/docker-compose.yml --env-file docker/.env down

# Stop and remove volumes (destructive)
docker compose -f docker/docker-compose.yml --env-file docker/.env down -v
```
