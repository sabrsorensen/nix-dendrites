{ config, lib, ... }:
lib.mkMerge [
  (lib.mkIf config.my.host.features.gui {
    my.host.features = {
      appimage = lib.mkDefault true;
      audio = lib.mkDefault true;
      desktop = lib.mkDefault (
        config.my.host.platform != "steamdeck" && config.my.host.platform != "wsl"
      );
      firefox = lib.mkDefault (
        config.my.host.platform != "steamdeck" && config.my.host.platform != "wsl"
      );
      homeGuiPackages = lib.mkDefault (config.my.host.platform != "wsl");
      konsole = lib.mkDefault true;
      localGuiTools = lib.mkDefault true;
      plymouth = lib.mkDefault true;
      wayland = lib.mkDefault true;
    };
  })

  (lib.mkIf config.my.host.features.decky {
    my.host.features = {
      deckyCatalog = lib.mkDefault true;
      deckyLoader = lib.mkDefault true;
      deckyPlugins = lib.mkDefault true;
    };
  })

  (lib.mkIf config.my.host.features.impermanence {
    my.host.features = {
      persistenceBluetooth = lib.mkDefault true;
      persistenceFirefox = lib.mkDefault true;
      persistenceHome = lib.mkDefault true;
      persistenceSystem = lib.mkDefault true;
    };
  })

  (lib.mkIf config.my.host.features.personalMcp {
    my.host.features = {
      mcpCommon = lib.mkDefault true;
      personalMcpServers = lib.mkDefault true;
    };
  })

  # Common MCP clients are part of the interactive workstation profile. Keep
  # this host-derived default so WSL and personal computers receive the same
  # shared server configuration without each host having to opt in manually.
  (lib.mkIf
    (
      config.my.host.platform == "wsl"
      || builtins.elem config.my.host.formFactor [
        "desktop"
        "laptop"
      ]
    )
    {
      my.host.features.mcpCommon = lib.mkDefault true;
    }
  )

  {
    my.host.is = {
      workstation = config.my.host.roles.workstation || config.my.host.features.gui;
      desktopSession = config.my.host.features.desktop;
      server = config.my.host.roles.server;
      rpi = config.my.host.platform == "rpi";
      steamdeck = config.my.host.platform == "steamdeck";
      headless = !config.my.host.features.gui;
    };
    nixpkgs.config.allowUnfreePredicate =
      pkg: builtins.elem (lib.getName pkg) config.my.unfreePackageNames;
    my.localDns.publishedRecords = lib.filter (record: record.ip != null) (
      map (
        record: record // { ip = if record.ip != null then record.ip else config.my.host.address; }
      ) config.my.localDns.records
    );
  }
]
