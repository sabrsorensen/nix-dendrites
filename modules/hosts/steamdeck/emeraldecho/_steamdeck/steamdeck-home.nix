# Steam Deck Home Manager configuration
{
  config,
  pkgs,
  lib,
  inputs,
  steamUser ? "sam",
  hostname,
  enableSecrets ? true,
  ...
}:
let
  sopsKeyPath = "${config.home.homeDirectory}/.ssh/sops_ed25519";
  isSteamDeck = builtins.elem hostname [
    "EmeraldEcho"
    "EmeraldEchoDualBoot"
  ];
  xrDriverRuntimeLibs = pkgs.lib.makeLibraryPath (
    with pkgs;
    [
      libevdev
      json_c
      curl
      openssl
      libusb1
      systemd
      wayland
    ]
  );
  steamConfigPython = pkgs.python3.withPackages (ps: [ ps.vdf ]);
  steamConfigSeedScript = pkgs.writeText "steam-config-seed.py" ''
    import collections
    import pathlib
    import shutil
    import sys

    import vdf

    config_path = pathlib.Path.home() / ".local/share/Steam/config/config.vdf"
    config_path.parent.mkdir(parents=True, exist_ok=True)

    STEAM_VALUES = {
        "WifiPowerManagementEnabled": "1",
        "AllowBatteryLowPowerDownloads": "1",
    }
    SHADER_CACHE_VALUES = {
        "EnableShaderBackgroundProcessing": "1",
    }
    UI_DISPLAY_CURRENT_VALUES = {
        "ScaleFactor": "1.2",
    }
    UI_DISPLAY_INTERNAL_VALUES = {
        "ScaleFactor": "1.2",
    }
    STEAMOS_VALUES = {
        "ChargeLimitEnabled": "1",
        "ChargeLimit": "90",
    }

    def nested_setdefault(mapping, keys):
        current = mapping
        for key in keys:
            current = current.setdefault(key, collections.OrderedDict())
        return current

    install_config = collections.OrderedDict()
    if config_path.exists():
        backup_path = config_path.with_suffix(config_path.suffix + ".pre-nix-backup")
        shutil.copy2(config_path, backup_path)
        try:
            with config_path.open("r", encoding="utf-8") as fp:
                install_config = vdf.load(fp, mapper=collections.OrderedDict)
        except Exception as exc:
            print(f"Failed to parse {config_path}: {exc}", file=sys.stderr)
            raise SystemExit(0)

    root = install_config.setdefault("InstallConfigStore", collections.OrderedDict())
    steam = nested_setdefault(root, ["Software", "Valve", "Steam"])
    system = steam.setdefault("System", collections.OrderedDict())
    system.update(STEAM_VALUES)
    shader_cache = steam.setdefault("ShaderCacheManager", collections.OrderedDict())
    shader_cache.update(SHADER_CACHE_VALUES)

    ui = root.setdefault("UI", collections.OrderedDict())
    display = ui.setdefault("display", collections.OrderedDict())
    current_display = display.setdefault("Current", collections.OrderedDict())
    current_display.update(UI_DISPLAY_CURRENT_VALUES)
    internal_display = display.setdefault('Internal: gamescope 7"', collections.OrderedDict())
    internal_display.update(UI_DISPLAY_INTERNAL_VALUES)

    steamos = root.setdefault("SteamOS", collections.OrderedDict())
    steamos.update(STEAMOS_VALUES)

    with config_path.open("w", encoding="utf-8") as fp:
        vdf.dump(install_config, fp, pretty=True, escaped=True)
  '';
in
{
  imports = [
    ../../../home-manager/home.nix
    ../../../home-manager/firefox/firefox.nix
    ../../../home-manager/vscode/vscode.nix
    ../../../home-manager/syncthing.nix
    ../../../home-manager/games/no-mans-sky.nix
    ./steamdeck-shortcut.nix
  ];

  home.username = steamUser;
  home.homeDirectory = "/home/${steamUser}";

  sops = lib.mkIf enableSecrets {
    age.sshKeyPaths = [ sopsKeyPath ];
    defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
    secrets = {
    };
  };

  # Steam Deck specific home packages
  home.packages = with pkgs; [
    # These packages are available in addition to system packages
  ];

  home.file = lib.mkIf isSteamDeck {
    ".config/reshade/Shaders/.keep".text = "";
    ".config/reshade/Textures/.keep".text = "";
    ".local/share/gamescope/reshade/Shaders/.keep".text = "";
    ".local/share/gamescope/reshade/Textures/.keep".text = "";
    ".local/share/breezy_vulkan/.keep".text = "";
  };

  systemd.user.services.xr-driver = lib.mkIf isSteamDeck {
    Unit = {
      Description = "XR user-space driver";
      After = [ "default.target" ];
      ConditionPathExists = "%h/.local/bin/xrDriver";
    };
    Service = {
      Type = "simple";
      Environment = [
        "LD_LIBRARY_PATH=%h/.local/share/xr_driver/lib:${xrDriverRuntimeLibs}"
      ];
      ExecStart = "%h/.local/bin/xrDriver";
      Restart = "always";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  home.activation.xrDriverCleanup = lib.mkIf isSteamDeck (
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f "$HOME/.config/systemd/user/default.target.wants/xr-driver.service"
    ''
  );

  home.activation.seedSteamConfig = lib.mkIf isSteamDeck (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${steamConfigPython}/bin/python3 ${steamConfigSeedScript}
    ''
  );
}
