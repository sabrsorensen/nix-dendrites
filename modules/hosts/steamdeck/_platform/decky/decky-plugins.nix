{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkOption types;
  cfg = config.jovian.decky-loader;

in
{
  options.jovian.decky-loader.plugins = mkOption {
    type = types.attrsOf types.package;
    default = { };
    example = lib.literalExpression ''
      {
        "decky-XRGaming" = pkgs.callPackage ../packages/decky-xrgaming.nix {};
      }
    '';
    description = ''
      Decky Loader plugins to install. Each plugin should be a derivation
      containing plugin.json, main.py, and any other required files.
    '';
  };

  config = mkIf (cfg.enable && cfg.plugins != { }) {
    # Bridge declarative Nix packages into Decky's mutable on-disk plugin
    # directory before the upstream loader starts.
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

        # Create plugins directory
        mkdir -p ${cfg.stateDir}/plugins
        chown ${cfg.user}:"$primary_group" ${cfg.stateDir} ${cfg.stateDir}/plugins

        # Remove old versions of plugins we're about to install
        ${lib.concatStrings (
          lib.mapAttrsToList (name: plugin: ''
            if [ -e ${cfg.stateDir}/plugins/${name} ]; then
              echo "Removing existing plugin: ${name}"
              rm -rf ${cfg.stateDir}/plugins/${name}
            fi
          '') cfg.plugins
        )}

        # Create plugin symlinks with clean names
        ${lib.concatStrings (
          lib.mapAttrsToList (name: plugin: ''
            echo "Installing plugin: ${name}"
            ln -sf ${plugin} ${cfg.stateDir}/plugins/${name}
            chown -h ${cfg.user}:"$primary_group" ${cfg.stateDir}/plugins/${name}
          '') cfg.plugins
        )}
      '';
    };

    # The upstream service expects plugins to already exist in its state dir.
    systemd.services.decky-loader = {
      after = [ "decky-loader-plugins.service" ];
      wants = [ "decky-loader-plugins.service" ];
    };
  };
}
