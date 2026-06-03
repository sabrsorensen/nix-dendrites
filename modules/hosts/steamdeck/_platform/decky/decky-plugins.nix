{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkOption types;
  cfg = config.jovian.decky-loader;

  # Function to build a plugin derivation from source
  buildDeckyPlugin =
    {
      name,
      src,
      version ? "dev",
      buildInputs ? [ ],
      buildPhase ? "",
      installPhase ? "",
      meta ? { },
    }:
    pkgs.stdenv.mkDerivation {
      pname = name;
      version = version;

      inherit src;

      buildInputs =
        with pkgs;
        [
          nodejs
          pnpm
          git
        ]
        ++ buildInputs;

      configurePhase = ''
        runHook preConfigure

        # Initialize git submodules if they exist
        if [ -f .gitmodules ]; then
          # Copy git files temporarily to allow submodule init
          export HOME=$TMPDIR
          git init
          git add .
          git -c user.email="builder@nixos" -c user.name="Nix Builder" commit -m "temp"

          # Initialize submodules
          git submodule update --init --recursive
        fi

        runHook postConfigure
      '';

      buildPhase = ''
        runHook preBuild

        # Build frontend if package.json exists
        if [ -f package.json ]; then
          export HOME=$TMPDIR
          pnpm install --frozen-lockfile --offline || pnpm install
          pnpm run build || true
        fi

        ${buildPhase}

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        # Create plugin directory
        mkdir -p $out

        # Copy all plugin files
        cp -r . $out/

        # Ensure main.py exists
        if [ ! -f $out/main.py ]; then
          echo "Error: Plugin must contain a main.py file"
          exit 1
        fi

        # Ensure plugin.json exists
        if [ ! -f $out/plugin.json ]; then
          echo "Error: Plugin must contain a plugin.json file"
          exit 1
        fi

        ${installPhase}

        runHook postInstall
      '';

      meta = {
        description = "Decky Loader plugin: ${name}";
        platforms = lib.platforms.linux;
      }
      // meta;
    };

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
