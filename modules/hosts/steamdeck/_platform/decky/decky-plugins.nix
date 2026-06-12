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
    # Pre-create plugin directories and symlinks
    systemd.services.decky-loader-plugins = {
      description = "Setup Decky Loader plugins";
      before = [ "decky-loader.service" ];
      wantedBy = [ "decky-loader.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        RemainAfterExit = true;
      };
      script = ''
        # Create plugins directory
        mkdir -p ${cfg.stateDir}/plugins

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
          '') cfg.plugins
        )}

        # Set ownership (query user's primary group dynamically)
        chown -R ${cfg.user}:$(id -gn ${cfg.user}) ${cfg.stateDir}
      '';
    };

    # Override the decky-loader service to depend on plugin setup
    systemd.services.decky-loader = {
      after = [ "decky-loader-plugins.service" ];
      wants = [ "decky-loader-plugins.service" ];
    };
  };
}
