{ ... }:
{
  # Keep the Decky plugin catalogue separate from the loader role.  Plugin
  # packages can be added incrementally while this bridge handles the mutable
  # state directory required by Decky itself.
  flake.modules.nixos.decky-plugins =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jovian.decky-loader;
      jsonType =
        let
          valueType = lib.types.nullOr (
            lib.types.oneOf [
              lib.types.bool
              lib.types.int
              lib.types.float
              lib.types.str
              (lib.types.listOf valueType)
              (lib.types.attrsOf valueType)
            ]
          );
        in
        valueType;
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
    {
      options.jovian.decky-loader.plugins = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
        default = { };
        description = "Declarative Decky Loader plugins keyed by their Decky directory name.";
      };
      options.jovian.decky-loader.seededSettings = lib.mkOption {
        type = lib.types.attrsOf jsonType;
        default = { };
        description = "JSON files to preseed under Decky Loader's settings directory.";
      };

      config = lib.mkMerge [
        (lib.mkIf (config.my.host.is.steamdeck && cfg.enable && cfg.plugins != { }) {
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
              mkdir -p ${cfg.stateDir}/plugins
              chown ${cfg.user}:"$primary_group" ${cfg.stateDir} ${cfg.stateDir}/plugins

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
        })
        (lib.mkIf (config.my.host.is.steamdeck && cfg.enable && cfg.seededSettings != { }) {
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
        })
      ];
    };
}
