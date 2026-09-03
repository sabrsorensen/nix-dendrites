# PostgreSQL 17 to 18 migration

Atlas currently stores Mealie's database in the PostgreSQL 17 cluster at
`/var/lib/postgresql/17`.  PostgreSQL 18 uses a separate cluster directory,
`/var/lib/postgresql/18`; starting it without a migration creates an empty
database.  This document describes the deliberate, offline migration required
before raising the Atlas system state version to `26.11`.

Do not change `system.stateVersion` to `26.11` until this migration has been
completed and verified.  The configuration currently remains at `26.05`, which
selects PostgreSQL 17 and therefore continues to use the existing Mealie data.

## Preconditions

- Schedule downtime for Mealie and every other service using Atlas's local
  PostgreSQL instance.
- Confirm the active cluster is PostgreSQL 17:

  ```sh
  sudo -u postgres psql -d postgres -c 'show server_version;'
  sudo -u postgres psql -d postgres -c '\\l'
  ```

- Take two independent backups before stopping services:

  ```sh
  sudo -u postgres pg_dumpall --clean --if-exists > /var/lib/postgresql/postgres-17-before-upgrade.sql
  sudo tar --xattrs --acls -C /var/lib/postgresql -cpf /var/lib/postgresql/postgres-17-before-upgrade.tar 17
  sudo tar --xattrs --acls -C /var/lib -cpf /var/lib/mealie-before-upgrade.tar mealie
  ```

  Copy the SQL dump and archives off Atlas before continuing.  The SQL dump is
  the recovery path if `pg_upgrade` cannot complete.

## Migration

1. Add PostgreSQL 18 explicitly in the Atlas configuration while retaining the
   existing PostgreSQL 17 package long enough to run its tools.  Do not deploy
   this as a normal unattended switch; use a configuration revision prepared
   specifically for the migration.
2. Stop Mealie and PostgreSQL:

   ```sh
   sudo systemctl stop mealie.service postgresql.service
   ```

3. Create `/var/lib/postgresql/18` with the ownership and permissions expected
   by the PostgreSQL service, then run the PostgreSQL 18 `pg_upgrade` utility
   against the v17 and v18 binaries.  Use `--check` first.  The exact Nix store
   paths must be taken from the prepared generation; do not substitute paths
   from a different revision.
4. Run the generated post-upgrade analyze script, if `pg_upgrade` produces one,
   and inspect its output.
5. Deploy the generation that selects PostgreSQL 18 and starts the service.

## Validation and rollback

After PostgreSQL and Mealie start, verify the database and application before
removing any old data:

```sh
sudo -u postgres psql -d postgres -c 'show server_version;'
sudo -u postgres psql -d mealie -c '\\dt'
sudo systemctl --no-pager --full status postgresql.service mealie.service
```

Sign in to Mealie and confirm recipes, users, images, and background jobs are
present.  Keep `/var/lib/postgresql/17` and the backups until this has been
verified over a normal operating period.

If validation fails, stop PostgreSQL, restore the configuration that selects
PostgreSQL 17, and restart it against `/var/lib/postgresql/17`.  If the old
cluster is damaged, restore the SQL dump into a freshly initialized PostgreSQL
17 cluster.  Do not attempt to run PostgreSQL 17 and 18 against the same data
directory.
