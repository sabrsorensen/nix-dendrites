# PostgreSQL 17 to 18 migration

AtlasUponRaiden's local PostgreSQL cluster lives at `/var/lib/postgresql/17`
and holds four databases, one per service:

| Database    | Owner       | Consumer units                                  |
| ----------- | ----------- | ----------------------------------------------- |
| `nextcloud` | `nextcloud` | `phpfpm-nextcloud`, `nextcloud-cron` (+ timer)  |
| `mealie`    | `mealie`    | `mealie`                                        |
| `immich`    | `immich`    | `immich-server`, `immich-machine-learning`      |
| `atuin`     | `atuin`     | `atuin`                                         |

The `immich` database uses the `vector` (pgvector 0.8.6) and `vchord`
(VectorChord 1.1.1) extensions.  Hawkbit's PostgreSQL runs in its own Docker
container (`docker-hawkbit-postgres`) and is not part of this migration.

Raising Atlas's `system.stateVersion` from `26.05` to `26.11` is what selects
PostgreSQL 18: the NixOS module switches `services.postgresql.package` to
`postgresql_18` and `dataDir` to `/var/lib/postgresql/18`.  Starting it
without a migration initialises an **empty** cluster there, and every service
above comes up against empty databases.  Nothing else on Atlas changes with
the `26.11` bump (verified by `nix-diff` of the two toplevels), and no other
host runs PostgreSQL.

Do not change Atlas's `system.stateVersion` to `26.11` until this migration
has been completed and verified.  Nextcloud is pinned explicitly
(`services.nextcloud.package`), so the state version bump does not change its
version; do not combine this migration with a Nextcloud major upgrade.

## Preconditions

- Schedule downtime for Nextcloud, Mealie, Immich and the Atuin sync server.
- Confirm the active cluster is PostgreSQL 17 and has the expected databases:

  ```sh
  sudo -u postgres psql -d postgres -c 'show server_version;'
  sudo -u postgres psql -d postgres -c '\l'
  sudo -u postgres psql -d immich -c '\dx'
  ```

- Confirm there is room for a second full copy of the cluster (the upgrade
  runs in copy mode, see below) and that no PostgreSQL 18 directory exists
  (if one does, see the end of "Rollback" before continuing):

  ```sh
  sudo du -sh /var/lib/postgresql/17
  df -h /var/lib/postgresql
  sudo ls -la /var/lib/postgresql
  ```

- Take independent backups while everything is still running:

  ```sh
  sudo -u postgres pg_dumpall --clean --if-exists \
    | sudo tee /var/lib/postgresql/postgres-17-before-upgrade.sql >/dev/null
  sudo tar --xattrs --acls -C /var/lib -cpf /var/lib/mealie-before-upgrade.tar mealie
  ```

  After stopping the services (step 2 below), also archive the raw cluster:

  ```sh
  sudo tar --xattrs --acls -C /var/lib/postgresql \
    -cpf /var/lib/postgresql/postgres-17-before-upgrade.tar 17
  ```

  Copy the SQL dump and archives off Atlas before continuing.  The SQL dump is
  the recovery path if `pg_upgrade` cannot complete.  Nextcloud's files
  (`/AnomalyRealm/nextcloud`) and Immich's media
  (`/AnomalyRealm/media/photos`) are not touched by the migration; only their
  database rows are.

## Migration tool

Deploy a one-off `upgrade-pg-cluster` command to Atlas first, as a normal
switch that still runs PostgreSQL 17.  It follows the host-specific concern
shape (see "Host-specific overrides" in `architecture.md`):

`modules/hosts/atlasuponraiden/pg-upgrade/pg-upgrade.nix`:

```nix
{ ... }:
{
  # One-off PostgreSQL 17 -> 18 migration tool; remove once the migration in
  # docs/postgresql-17-to-18-migration.md is verified.
  flake.modules.nixos.pg-upgrade-atlasuponraiden =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.name == "AtlasUponRaiden") (import ./_pg-upgrade.nix args);
}
```

`modules/hosts/atlasuponraiden/pg-upgrade/_pg-upgrade.nix`:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.postgresql;
  # Must carry every extension used by the old cluster, or pg_upgrade --check
  # fails on the missing shared libraries.
  newPostgres = pkgs.postgresql_18.withPackages (pp: [
    pp.pgvector
    pp.vectorchord
  ]);
  # pg_upgrade starts both servers with their data directories' own
  # postgresql.conf, not the NixOS-managed one, so preloads the module sets
  # (vchord, required by Immich) must be passed explicitly.
  preload = lib.concatStringsSep "," (lib.toList (cfg.settings.shared_preload_libraries or [ ]));
  serverOptions = lib.optionalString (preload != "") "-c shared_preload_libraries=${preload}";
  consumers = [
    "phpfpm-nextcloud.service"
    "nextcloud-cron.timer"
    "nextcloud-cron.service"
    "mealie.service"
    "immich-server.service"
    "immich-machine-learning.service"
    "atuin.service"
  ];
in
{
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "upgrade-pg-cluster";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.util-linux
      ];
      text = ''
        OLDDATA=${lib.escapeShellArg cfg.dataDir}
        OLDBIN=${cfg.finalPackage}/bin
        NEWDATA=/var/lib/postgresql/${newPostgres.psqlSchema}
        NEWBIN=${newPostgres}/bin

        for unit in ${lib.escapeShellArgs consumers} postgresql.service; do
          if systemctl is-active --quiet "$unit"; then
            echo "$unit is still active; stop it first" >&2
            exit 1
          fi
        done

        # Only ever reuse a new cluster this tool initialised itself (so a
        # --check run can be followed by the real one).  Anything else there
        # came from somewhere unknown and must be inspected and moved aside.
        MARKER="$NEWDATA.upgrade-pg-cluster-initdb"
        if [ -e "$NEWDATA" ] && [ ! -e "$MARKER" ]; then
          echo "$NEWDATA already exists and was not created by upgrade-pg-cluster;" >&2
          echo "inspect it and move it aside before migrating" >&2
          exit 1
        fi

        if [ ! -d "$NEWDATA" ]; then
          install -d -m 0700 -o postgres -g postgres "$NEWDATA"
          touch "$MARKER"
          # PostgreSQL 18's initdb enables data checksums by default, and
          # pg_upgrade refuses to migrate between clusters whose checksum
          # settings differ.  Match the old cluster.
          checksums=()
          if "$OLDBIN/pg_controldata" "$OLDDATA" \
              | grep -q '^Data page checksum version:[[:space:]]*0$'; then
            checksums=(--no-data-checksums)
          fi
          runuser -u postgres -- "$NEWBIN/initdb" -D "$NEWDATA" \
            ${lib.escapeShellArgs cfg.initdbArgs} "''${checksums[@]}"
        fi

        # pg_upgrade writes its logs to the working directory.
        cd "$NEWDATA"
        runuser -u postgres -- "$NEWBIN/pg_upgrade" \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir "$OLDBIN" --new-bindir "$NEWBIN" \
          --old-options ${lib.escapeShellArg serverOptions} \
          --new-options ${lib.escapeShellArg serverOptions} \
          "$@"
      '';
    })
  ];
}
```

`git add -N` both files, then confirm the tool is in Atlas's configuration and
that the state version is still `26.05` before deploying:

```sh
nix eval --raw .#nixosConfigurations.atlasuponraiden.config.system.stateVersion
nix eval --raw .#nixosConfigurations.atlasuponraiden.config.services.postgresql.package.version
```

## Migration

1. Deploy the generation containing `upgrade-pg-cluster` (PostgreSQL 17 still
   active).  Keep this revision; the rollback path below returns to it.
2. Stop every consumer, then PostgreSQL:

   ```sh
   sudo systemctl stop phpfpm-nextcloud.service nextcloud-cron.timer \
     nextcloud-cron.service mealie.service immich-server.service \
     immich-machine-learning.service atuin.service
   sudo systemctl stop postgresql.service
   ```

   Take the raw cluster archive from the preconditions now.
3. Dry-run the upgrade.  This initialises `/var/lib/postgresql/18` (matching
   the old cluster's checksum setting) and checks compatibility without
   touching the old cluster:

   ```sh
   sudo upgrade-pg-cluster --check
   ```

   Resolve anything it reports before continuing.  `vchord` must be in
   `shared_preload_libraries`, which lives in the NixOS-managed config file
   rather than either data directory's `postgresql.conf`; the tool passes the
   configured preloads to both servers (`--old-options`/`--new-options`),
   otherwise the check fails with `vchord must be loaded via
   shared_preload_libraries` in `loadable_libraries.txt`.  If it complains about
   encoding or locale mismatches, delete `/var/lib/postgresql/18`, add the
   matching `--encoding`/`--locale` to `services.postgresql.initdbArgs`,
   redeploy the tool, and rerun `--check`.
4. Run the upgrade in the default copy mode.  Do **not** pass `--link`: copy
   mode leaves `/var/lib/postgresql/17` intact and startable, which the
   rollback path depends on.

   ```sh
   sudo upgrade-pg-cluster --jobs "$(nproc)"
   ```

5. Set `system.stateVersion = "26.11";` in Atlas's `hostModule`
   (`modules/hosts/atlasuponraiden/host/_host.nix`); it overrides the
   `mkDefault` in `modules/system/base/_base.nix`.  Leave the other hosts
   alone for now.  Confirm the evaluated result, then deploy.  The consumers
   start again with the switch.

   ```sh
   nix eval --raw .#nixosConfigurations.atlasuponraiden.config.services.postgresql.dataDir
   # /var/lib/postgresql/18
   ```

6. Run the `vacuumdb` command printed at the end of step 4 (PostgreSQL 18's
   `pg_upgrade` carries planner statistics over, so it only needs to fill in
   what is missing) and inspect its output.

## Validation

Check the server and every database before removing any old data:

```sh
sudo -u postgres psql -d postgres -c 'show server_version;'
sudo -u postgres psql -d postgres -c '\l'
sudo -u postgres psql -d immich -c '\dx'
for db in nextcloud mealie immich atuin; do
  sudo -u postgres psql -d "$db" -c '\dt' | tail -n 1
done
sudo systemctl --no-pager --failed
sudo systemctl --no-pager --full status postgresql.service \
  phpfpm-nextcloud.service mealie.service immich-server.service atuin.service
sudo nextcloud-occ status
```

Then check each application:

- **Nextcloud**: sign in, open files, and open a document in Collabora
  (confirms `nextcloud-richdocuments` ran).  `nextcloud-occ status` must show
  `maintenance: false`.
- **Mealie**: sign in; recipes, users, images and meal plans are present.
- **Immich**: timeline loads and smart search (the `vchord`/`vector` indexes)
  returns results.
- **Atuin**: `atuin sync` from a client succeeds without re-registering.

Keep `/var/lib/postgresql/17` and the backups until everything has run
normally for a while.  Then remove the migration tool module, and delete the
old cluster, the `delete_old_cluster.sh` that `pg_upgrade` left in
`/var/lib/postgresql/18`, and the tool's marker file
`/var/lib/postgresql/18.upgrade-pg-cluster-initdb`.

## Rollback

Because the upgrade ran in copy mode, the PostgreSQL 17 cluster is unchanged.
To go back: stop the consumers and PostgreSQL, move `/var/lib/postgresql/18`
aside, and redeploy (or `switch` back to) the step-1 generation with
`system.stateVersion = "26.05"`.  Any data written while on 18 is lost.  If
the old cluster is damaged, restore the raw archive, or restore the SQL dump
into a freshly initialised PostgreSQL 17 cluster.  Never point PostgreSQL 17
and 18 at the same data directory.

If PostgreSQL 18 is ever started on Atlas before the migration (for example
by an accidental `26.11` deploy), it creates an empty `/var/lib/postgresql/18`
and the services may create empty schemas in it.  The tool refuses to run
against a `/var/lib/postgresql/18` it did not initialise itself (it records
its own `initdb` in `/var/lib/postgresql/18.upgrade-pg-cluster-initdb`, so a
`--check` run can be followed by the real one).  Inspect the stray directory
to be sure it holds nothing you need:

```sh
sudo ls -la /var/lib/postgresql /var/lib/postgresql/18
sudo cat /var/lib/postgresql/18/PG_VERSION
sudo ls /var/lib/postgresql/18/base    # 1, 4, 5 only = no user databases
sudo du -sh /var/lib/postgresql/18
sudo journalctl -u postgresql.service -g '/var/lib/postgresql/18' --no-pager | head
```

Then move it aside (for example to `/var/lib/postgresql/18.stray-<date>`)
with PostgreSQL stopped, and delete it once the migration is verified.
