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
  warnings = [
    ''
      AtlasUponRaiden's PostgreSQL 17 -> 18 migration (2026-09-29) is not
      finished: finish the migration after October 6th, once PostgreSQL 18,
      Nextcloud, Mealie, Immich and Atuin have run stably through a normal
      backup cycle. Until then /var/lib/postgresql/17 and the
      *-before-upgrade backups are the rollback path -- don't delete them early.
      To finish (details in docs/postgresql-17-to-18-migration.md):
        1. Take a PostgreSQL 18 baseline pg_dumpall and copy it off Atlas.
        2. Remove modules/hosts/atlasuponraiden/pg-upgrade/ (this warning goes
           with it), mark the migration doc done, and deploy.
        3. On Atlas, after confirming `show data_directory` is
           /var/lib/postgresql/18, delete /var/lib/postgresql/17,
           /var/lib/postgresql/18.stray-2026-07-25,
           /var/lib/postgresql/18.upgrade-pg-cluster-initdb,
           /var/lib/postgresql/18/delete_old_cluster.sh,
           /var/lib/postgresql/18/pg_upgrade_output.d,
           /var/lib/postgresql/postgres-17-before-upgrade.{sql,tar} and
           /var/lib/mealie-before-upgrade.tar.
    ''
  ];

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
