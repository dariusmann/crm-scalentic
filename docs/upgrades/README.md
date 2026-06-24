# Upgrade checklist

Use this template when upgrading Twenty. Official guide: [Twenty upgrade guide](https://docs.twenty.com/developers/self-host/capabilities/upgrade-guide).

## Per-upgrade record

Create a file named `docs/upgrades/YYYY-MM-DD-vX.Y.Z.md` for each upgrade.

### Template

```markdown
# Upgrade: vOLD → vNEW

- **Date:**
- **Previous TAG:**
- **New TAG:**
- **Backup file:** backups/twenty_YYYYMMDD_HHMMSS.sql
- **Performed by:**

## Pre-upgrade

- [ ] Read [Twenty release notes](https://github.com/twentyhq/twenty/releases) for breaking changes
- [ ] Backup created via `./scripts/backup-db.sh` (or via upgrade script)

## Upgrade steps

- [ ] Ran `./scripts/upgrade-twenty.sh vNEW`
- [ ] `upgrade:status` shows no failures

## Smoke tests

- [ ] Login works
- [ ] Create a test record (person or company)
- [ ] Existing records load correctly
- [ ] Webhooks / integrations still work (if configured)

## Notes

<!-- Any issues, rollback steps, or changelog items relevant to this deployment -->
```

## Cross-version upgrades

From Twenty v1.22 onward, you can jump directly between supported versions (e.g. v1.22 → v2.14.0). For instances older than v1.22, upgrade incrementally through each major tagged version until you reach v1.22.

## Rollback

1. Stop the stack: `docker compose -f docker/docker-compose.yml --env-file docker/.env down`
2. Restore the backup (see [docker/README.md](../../docker/README.md#restore-from-backup))
3. Revert `TAG` in `docker/.env` to the previous version
4. Start the stack: `docker compose -f docker/docker-compose.yml --env-file docker/.env up -d`

## Troubleshooting

If upgrade migrations fail, the server will not advance past the failing step. Restarting (`docker compose up -d`) retries from where it left off.

```bash
docker compose -f docker/docker-compose.yml --env-file docker/.env exec server yarn command:prod upgrade:status
docker compose -f docker/docker-compose.yml --env-file docker/.env exec server yarn command:prod upgrade:status --failed-only
```
