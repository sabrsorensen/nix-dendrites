{
  flake.modules.nixos.bazarr =
  {
    lib,
    pkgs,
    ...
  }:
  let
  arr = import ../_arr/lib.nix { inherit lib; };
    groupName = "media";
    listenPort = 6767;
    listenPort4k = 6768;
    localAddr = "127.0.0.1:${lib.toString listenPort}";
    localAddr4k = "127.0.0.1:${lib.toString listenPort4k}";
    serviceName = "bazarr";
  in
  {
    my.media.caddy.apexRoutes = [
      (arr.mkThemeParkRoute {
        inherit localAddr serviceName;
        marker = "</head>";
      })
      (arr.mkThemeParkRoute {
        inherit serviceName;
        localAddr = localAddr4k;
        marker = "</head>";
        pathSuffix = "4k";
      })
    ];

    services.bazarr = {
      enable = true;
      openFirewall = false;
      listenPort = listenPort;
      group = groupName;
    };

    users.users."${serviceName}".group = "media";
    systemd.services."${serviceName}4k" = arr.mkManagedService {
      description = "Bazarr 4K";
      execStart = "${pkgs.bazarr}/bin/bazarr -c=/var/lib/bazarr4k --port=${lib.toString listenPort4k}";
      user = serviceName;
      group = groupName;
      extraServiceConfig.KillSignal = "SIGINT";
    };
  };
}
