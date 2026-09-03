{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  returnToGamingEntry = {
    name = "Return to Gaming Mode";
    exec = "qdbus org.kde.Shutdown /Shutdown logout";
    icon = "steam";
    terminal = false;
    categories = [ "System" ];
    comment = "Logout and return to Steam";
  };
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
    steam = root.setdefault("Software", collections.OrderedDict()).setdefault("Valve", collections.OrderedDict()).setdefault("Steam", collections.OrderedDict())
    steam.setdefault("System", collections.OrderedDict()).update({
        "WifiPowerManagementEnabled": "1",
        "AllowBatteryLowPowerDownloads": "1",
    })
    steam.setdefault("ShaderCacheManager", collections.OrderedDict()).update({
        "EnableShaderBackgroundProcessing": "1",
    })
    display = root.setdefault("UI", collections.OrderedDict()).setdefault("display", collections.OrderedDict())
    display.setdefault("Current", collections.OrderedDict()).update({"ScaleFactor": "1.2"})
    display.setdefault('Internal: gamescope 7"', collections.OrderedDict()).update({"ScaleFactor": "1.2"})
    root.setdefault("SteamOS", collections.OrderedDict()).update({
        "ChargeLimitEnabled": "1",
        "ChargeLimit": "90",
    })

    with config_path.open("w", encoding="utf-8") as fp:
        vdf.dump(install_config, fp, pretty=True, escaped=True)
  '';
in
{
  xdg = {
    enable = true;
    desktopEntries.return-to-gaming = returnToGamingEntry;
  };

  home.file = {
    ".config/reshade/Shaders/.keep".text = "";
    ".config/reshade/Textures/.keep".text = "";
    ".local/share/gamescope/reshade/Shaders/.keep".text = "";
    ".local/share/gamescope/reshade/Textures/.keep".text = "";
    ".local/share/breezy_vulkan/.keep".text = "";
    "Desktop/return-to-gaming.desktop".text = ''
      [Desktop Entry]
      Name=${returnToGamingEntry.name}
      Exec=${returnToGamingEntry.exec}
      Icon=${returnToGamingEntry.icon}
      Terminal=${if returnToGamingEntry.terminal then "true" else "false"}
      Type=Application
      Categories=${builtins.concatStringsSep ";" returnToGamingEntry.categories};
      Comment=${returnToGamingEntry.comment}
    '';
  };

  systemd.user.services.xr-driver = {
    Unit = {
      Description = "XR user-space driver";
      After = [ "default.target" ];
      ConditionPathExists = "%h/.local/bin/xrDriver";
    };
    Service = {
      Type = "simple";
      Environment = [ "LD_LIBRARY_PATH=%h/.local/share/xr_driver/lib:${xrDriverRuntimeLibs}" ];
      ExecStart = "%h/.local/bin/xrDriver";
      Restart = "always";
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.activation = {
    xrDriverCleanup = inputs.home-manager.lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f "$HOME/.config/systemd/user/default.target.wants/xr-driver.service"
    '';
    seedSteamConfig = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${steamConfigPython}/bin/python3 ${steamConfigSeedScript}
    '';
  };
}
