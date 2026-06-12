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
  systemctlActions = [
    "is-active"
    "daemon-reload"
    "restart"
    "stop"
    "start"
  ];
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

  deckyLoaderCompatibilityReplacements = [
    {
      file = "backend/decky_loader/localplatform/localplatformlinux.py";
      reason = "Preserve PATH when Decky clears its Linux subprocess environment.";
      old = ''env: ENV | None = {"LD_LIBRARY_PATH": ""}'';
      new = ''env: ENV | None = {"LD_LIBRARY_PATH": "", "PATH": os.environ.get("PATH", "")}'';
      expectedCount = 1;
    }
  ]
  ++ map
    (
      action:
      let
        oldSuffix = if action == "daemon-reload" then ''["systemctl", "${action}"]'' else ''["systemctl", "${action}", service_name]'';
        newSuffix =
          if action == "daemon-reload" then
            ''["${pkgs.systemd}/bin/systemctl", "${action}"]''
          else
            ''["${pkgs.systemd}/bin/systemctl", "${action}", service_name]'';
      in
      {
        file = "backend/decky_loader/localplatform/localplatformlinux.py";
        reason = "Resolve systemctl from the Nix store instead of assuming a mutable host PATH.";
        old = oldSuffix;
        new = newSuffix;
        expectedCount = 1;
      }
    )
    systemctlActions
  ++ [
    {
      file = "backend/decky_loader/helpers.py";
      reason = "Use the packaged Python interpreter when Decky spawns Linux helpers.";
      old = ''["python3" if localplatform.ON_LINUX else "python", "-c",'';
      new = ''["${pkgs.python3}/bin/python3" if localplatform.ON_LINUX else "python", "-c",'';
      expectedCount = 1;
    }
    {
      file = "backend/decky_loader/helpers.py";
      reason = "Keep PATH available for Linux helper subprocesses.";
      old = ''env={} if localplatform.ON_LINUX else None'';
      new = ''env={"PATH": os.environ.get("PATH", "")} if localplatform.ON_LINUX else None'';
      expectedCount = 1;
    }
  ];

  deckyLoaderCompatibilityManifest = pkgs.writeText "decky-loader-compatibility.json" (
    builtins.toJSON deckyLoaderCompatibilityReplacements
  );

  # Jovian packages Decky for NixOS, but upstream Decky still assumes a mutable
  # host PATH and unqualified tool names. Keep the local bridge small and list
  # each exact source rewrite explicitly so future rebases fail loudly.
  deckyLoaderPackage = pkgs.decky-loader.overridePythonAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      python3 - <<'PY'
      import json
      import pathlib
      import sys

      replacements = json.loads(pathlib.Path("${deckyLoaderCompatibilityManifest}").read_text())

      grouped = {}
      for replacement in replacements:
          grouped.setdefault(replacement["file"], []).append(replacement)

      for file_name, file_replacements in grouped.items():
          path = pathlib.Path(file_name)
          text = path.read_text(encoding="utf-8")
          for replacement in file_replacements:
              old = replacement["old"]
              new = replacement["new"]
              count = text.count(old)
              expected_count = replacement.get("expectedCount", 1)
              if count != expected_count:
                  print(
                      f"unexpected match count in {file_name}: {replacement['reason']}",
                      file=sys.stderr,
                  )
                  print(f"expected {expected_count}, found {count}", file=sys.stderr)
                  print(old, file=sys.stderr)
                  sys.exit(1)
              text = text.replace(old, new, expected_count)
          path.write_text(text, encoding="utf-8")
      PY
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
    # Keep the compatibility surface narrow: only add the interpreter that
    # upstream Decky still assumes exists in the interactive system profile.
    environment.systemPackages = lib.mkIf cfg.enable (
      with pkgs;
      [
        python3
      ]
    );

    # Several third-party Decky plugins still ship dynamically linked helper
    # binaries that are not packaged for NixOS.
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc
      glibc
      zlib
      openssl
      libgcc
    ];

    # Jovian owns the service shape; this module only layers compatibility and
    # declarative plugin packaging on top.
    jovian.decky-loader = {
      enable = true;
      package = deckyLoaderPackage;
      user = lib.mkDefault steamUser;
      extraPackages = with pkgs; [
        coreutils
        hidapi
        psmisc
        python3
        steam-run
        systemd
      ];
      extraPythonPackages =
        pythonPackages: with pythonPackages; [
          click # KDE Connect plugin
          vdf # SteamGridDB plugin
        ];
    };

    # Decky integrates with Steam's embedded browser and expects this toggle to
    # exist before startup on some hosts.
    systemd.services.steam-cef-debug = lib.mkIf config.jovian.decky-loader.enable {
      description = "Seed Steam CEF debugging toggle for Decky Loader";
      serviceConfig = {
        Type = "oneshot";
        User = config.jovian.steam.user;
        ExecStart = steamCefDebugScript;
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Keep runtime library injection minimal. Loader compatibility fixes should
    # live in the packaged Decky override above whenever possible.
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
        # Third-party plugins commonly discover user services over D-Bus.
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${
          toString config.users.users.${config.jovian.steam.user}.uid
        }/bus";
        DBUS_SYSTEM_BUS_ADDRESS = "unix:path=/run/dbus/system_bus_socket";
      };
    };

    systemd.services.decky-settings-seed = lib.mkIf (cfg.enable && cfg.seededSettings != { }) {
      description = "Seed declarative Decky Loader settings";
      before = [ "decky-loader.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = deckySeededSettingsScript;
      };
    };
  };
}
