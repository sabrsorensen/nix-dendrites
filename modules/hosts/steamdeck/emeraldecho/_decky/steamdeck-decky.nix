{
  steamUser ? "sam",
}:
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

  deckyLoaderPackage = pkgs.decky-loader.overridePythonAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace backend/decky_loader/localplatform/localplatformlinux.py \
        --replace-fail 'env: ENV | None = {"LD_LIBRARY_PATH": ""}' \
                       'env: ENV | None = {"LD_LIBRARY_PATH": "", "PATH": os.environ.get("PATH", "")}' \
        --replace-warn '"systemctl"' '"${pkgs.systemd}/bin/systemctl"'

      substituteInPlace backend/decky_loader/helpers.py \
        --replace-fail 'env={} if localplatform.ON_LINUX else None' \
                       'env={"PATH": os.environ.get("PATH", "")} if localplatform.ON_LINUX else None' \
        --replace-warn '"python3"' '"${pkgs.python3}/bin/python3"'
    '';
  });

  steamCefDebugScript = pkgs.writeShellScript "steam-cef-debug" ''
    set -eu
    steam_root=""

    if [ -e "$HOME/.steam/steam" ]; then
      steam_root="$HOME/.steam/steam"
    elif [ -d "$HOME/.local/share/Steam" ]; then
      steam_root="$HOME/.local/share/Steam"
    fi

    if [ -n "$steam_root" ] && [ ! -f "$steam_root/.cef-enable-remote-debugging" ]; then
      touch "$steam_root/.cef-enable-remote-debugging"
    fi
  '';

  deckySeededSettingsPackage = pkgs.runCommandLocal "decky-seeded-settings" { } (
    ''
      mkdir -p "$out"
    ''
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

  deckySeededSettingsScript = pkgs.writeShellScript "seed-decky-settings" ''
    set -eu

    src="${deckySeededSettingsPackage}"
    dst="/var/lib/decky-loader/settings"

    mkdir -p "$dst"

    while IFS= read -r rel; do
      mkdir -p "$dst/$(dirname "$rel")"
      install -m 0644 "$src/$rel" "$dst/$rel"
      chown ${config.jovian.steam.user}:${config.jovian.steam.user} "$dst/$rel"
    done < <(cd "$src" && find . -type f -printf '%P\n')
  '';
in

{
  imports = [
    # Plugin-specific fix modules
    ./plugins/xrgaming.nix
  ];

  options.jovian.decky-loader.seededSettings = lib.mkOption {
    type = lib.types.attrsOf jsonType;
    default = { };
    description = "JSON files to preseed under /var/lib/decky-loader/settings.";
    example = lib.literalExpression ''
      {
        "DeckWebBrowser/settings.json" = {
          defaultTabs = [ "home" ];
          menuPosition = 2;
          searchEngine = 0;
        };
      }
    '';
  };

  config = {
    # Add python3 to system packages for decky-loader compatibility
    environment.systemPackages = lib.mkIf cfg.enable (
      with pkgs;
      [
        python3
      ]
    );

    # Enable nix-ld for running dynamically linked executables in decky-loader plugins
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc
      glibc
      zlib
      openssl
      libgcc
    ];

    # Basic decky-loader configuration
    jovian.decky-loader = {
      enable = true;
      package = deckyLoaderPackage;
      user = lib.mkDefault steamUser;
      extraPackages = with pkgs; [
        coreutils
        psmisc
        python3
        shadow
        steam-run
        systemd
      ];
      extraPythonPackages =
        pythonPackages: with pythonPackages; [
          click # KDE Connect plugin
          vdf # SteamGridDB plugin
        ];
    };

    # Create Steam CEF debugging file if it doesn't exist for Decky Loader.
    systemd.services.steam-cef-debug = lib.mkIf config.jovian.decky-loader.enable {
      description = "Create Steam CEF debugging file";
      serviceConfig = {
        Type = "oneshot";
        User = config.jovian.steam.user;
        ExecStart = steamCefDebugScript;
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Override decky-loader service to fix PATH without heavy library overhead
    systemd.services.decky-loader = lib.mkIf config.jovian.decky-loader.enable {
      environment = {
        # Minimal LD_LIBRARY_PATH with only essential libraries for decky-loader itself
        LD_LIBRARY_PATH = lib.makeLibraryPath (
          with pkgs;
          [
            glibc
            stdenv.cc.cc.lib
            zlib
            openssl
          ]
        );
        # Set up D-Bus environment for plugins that need it
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${
          toString config.users.users.${config.jovian.steam.user}.uid
        }/bus";
        DBUS_SYSTEM_BUS_ADDRESS = "unix:path=/run/dbus/system_bus_socket";
      };
    };

    systemd.services.decky-settings-seed = lib.mkIf (cfg.enable && cfg.seededSettings != { }) {
      description = "Seed Decky Loader settings";
      before = [ "decky-loader.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = deckySeededSettingsScript;
      };
    };
  };
}
