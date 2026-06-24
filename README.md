# Scalentic CRM

Self-hosted [Twenty CRM](https://twenty.com) with upgrade-friendly Docker deployment. Twenty core runs from official upstream images; this repo owns deployment config and operational scripts only.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- 2 GB+ RAM available

## Quick start

```bash
cp docker/.env.example docker/.env
# Edit docker/.env: set ENCRYPTION_KEY and PG_DATABASE_PASSWORD (see docker/README.md)

docker compose -f docker/docker-compose.yml --env-file docker/.env up -d
```

Open http://localhost:3000 and complete first-time setup.

## Project layout

```
scalentic-crm/
├── docker/           # Compose stack and environment config
├── scripts/          # Backup and upgrade automation
├── docs/upgrades/    # Upgrade checklists and records
└── backups/          # Database dumps (gitignored)
```

## Upgrading Twenty

Pin versions in `docker/.env` (`TAG=v2.14.0`). To upgrade:

```bash
./scripts/upgrade-twenty.sh v2.15.0
```

The script backs up the database, updates `TAG`, pulls images, restarts, and waits for the health check. See [docs/upgrades/README.md](docs/upgrades/README.md) for the full checklist.

## Production (later)

Same compose file; change environment only:

- Set `SERVER_URL` to your public HTTPS domain
- Add a reverse proxy with TLS in front of port 3000
- Never use `TAG=latest` in production
- Automate backups with cron (see [docker/README.md](docker/README.md))

## Future extensions

Not implemented in this scaffold — documented here as extension points:

### `services/` — Python integrations

External microservices (FastAPI, Celery workers) that talk to Twenty via:

- **Webhooks (out):** Twenty pushes record events to your API
- **GraphQL / REST (in):** Your code reads and writes CRM data
- **Workflow HTTP steps:** Triggered from Twenty workflows

Keep Python code outside the Twenty container so upgrades stay isolated.

### `twenty-app/` — TypeScript platform extensions

Deep CRM customizations using the [Twenty SDK](https://docs.twenty.com/developers/extend/extend):

- Custom objects and fields as code
- Logic functions (HTTP routes, cron, DB events)
- UI components inside Twenty

Develop with `yarn twenty dev`, publish with `yarn twenty app:publish`.

## Documentation

- [docker/README.md](docker/README.md) — environment variables, backup, restore
- [docs/upgrades/README.md](docs/upgrades/README.md) — upgrade checklist
- [Twenty self-hosting docs](https://docs.twenty.com/developers/self-host/capabilities/docker-compose)
