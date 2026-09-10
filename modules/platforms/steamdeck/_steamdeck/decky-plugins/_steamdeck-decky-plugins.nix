{
  config,
  lib,
  pkgs,
  cfg,
  ...
}:
let
  seededSettings = pkgs.runCommandLocal "decky-seeded-settings" { } (
    ''mkdir -p "$out"''
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        relativePath: value:
        let
          parentDir = builtins.dirOf relativePath;
          jsonFile = pkgs.writeText "decky-setting-${lib.replaceStrings [ "/" "." ] [ "-" "-" ] relativePath}" (
            builtins.toJSON value
          );
        in
        ''
          mkdir -p "$out/${if parentDir == "." then "" else parentDir}"
          cp ${jsonFile} "$out/${relativePath}"
        ''
      ) cfg.seededSettings
    )
  );
  seedScript = pkgs.writeShellScript "seed-decky-settings" ''
    set -eu
    src="${seededSettings}"
    dst="${cfg.stateDir}/settings"
    mkdir -p "$dst"
    while IFS= read -r rel; do
      mkdir -p "$dst/$(dirname "$rel")"
      install -m 0644 "$src/$rel" "$dst/$rel"
      chown ${cfg.user}:"$(id -gn ${cfg.user})" "$dst/$rel"
    done < <(cd "$src" && find . -type f -printf '%P\n')
  '';
in
lib.mkMerge [
  (lib.mkIf
    (
      config.my.host.platform == "steamdeck"
      && config.my.host.features.deckyPlugins
      && cfg.enable
      && cfg.plugins != { }
    )
    {
      systemd.services.decky-loader-plugins = {
        description = "Stage declarative Decky Loader plugins";
        before = [ "decky-loader.service" ];
        wantedBy = [ "decky-loader.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          RemainAfterExit = true;
        };
        script = ''
          primary_group="$(id -gn ${cfg.user})"
          plugins_dir=${cfg.stateDir}/plugins
          mkdir -p "$plugins_dir"
          chown ${cfg.user}:"$primary_group" ${cfg.stateDir} "$plugins_dir"

          # Plugin dir names this generation stages. Any *other* entry that is
          # a symlink is a previously-staged plugin this module no longer owns
          # (typically left behind under an old name after a catalog rename) —
          # remove it so it stops being loaded. A real directory is a plugin
          # the user installed by hand through Decky's UI; leave those alone.
          managed=(${
            lib.concatStringsSep " " (map (name: lib.escapeShellArg name) (lib.attrNames cfg.plugins))
          })
          for entry in "$plugins_dir"/*; do
            if [ ! -L "$entry" ]; then
              continue
            fi
            name="$(basename "$entry")"
            keep=0
            for m in "''${managed[@]}"; do
              if [ "$m" = "$name" ]; then
                keep=1
                break
              fi
            done
            if [ "$keep" -eq 0 ]; then
              echo "Removing stale staged Decky plugin: $name"
              rm -f "''${entry:?}"
            fi
          done

          ${lib.concatStrings (
            lib.mapAttrsToList (name: _: ''
              rm -rf ${cfg.stateDir}/plugins/${name}
            '') cfg.plugins
          )}

          ${lib.concatStrings (
            lib.mapAttrsToList (name: plugin: ''
              ln -sfn ${plugin} ${cfg.stateDir}/plugins/${name}
              chown -h ${cfg.user}:"$primary_group" ${cfg.stateDir}/plugins/${name}
            '') cfg.plugins
          )}
        '';
      };

      systemd.services.decky-loader = {
        after = [ "decky-loader-plugins.service" ];
        wants = [ "decky-loader-plugins.service" ];
      };
    }
  )
  (lib.mkIf
    (
      config.my.host.platform == "steamdeck"
      && config.my.host.features.deckyPlugins
      && cfg.enable
      && cfg.seededSettings != { }
    )
    {
      systemd.services.decky-settings-seed = {
        description = "Seed declarative Decky Loader settings";
        before = [ "decky-loader.service" ];
        wantedBy = [ "decky-loader.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = seedScript;
        };
      };
      systemd.services.decky-loader = {
        after = [ "decky-settings-seed.service" ];
        wants = [ "decky-settings-seed.service" ];
      };
    }
  )
]
