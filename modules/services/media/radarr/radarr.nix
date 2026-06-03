{
  flake.modules.nixos.radarr =
  {
    lib,
    pkgs,
    ...
  }:
  let
  arr = import ../_arr/lib.nix { inherit lib; };
    bindAddr = "127.0.0.1";
    groupName = "media";
    port = 7878;
    port4k = 7879;
    localAddr = "${bindAddr}:${lib.toString port}";
    localAddr4k = "${bindAddr}:${lib.toString port4k}";
    serviceName = "radarr";
  in
  {
    my.media.caddy.apexRoutes = [
      (arr.mkThemeParkRoute {
        inherit localAddr serviceName;
      })
      (arr.mkThemeParkRoute {
        inherit serviceName;
        localAddr = localAddr4k;
        pathSuffix = "4k";
      })
    ];

    services.radarr = {
      enable = true;
      openFirewall = false;
      group = groupName;
      settings.server = {
        urlbase = "/${serviceName}";
        port = port;
        bindaddress = bindAddr;
      };
    };

    users.users.${serviceName}.group = groupName;
    systemd.services.radarr4k = arr.mkManagedService {
      description = "Radarr 4K";
      execStart = "${pkgs.radarr}/bin/Radarr -nobrowser -data=/var/lib/radarr4k";
      user = serviceName;
      group = groupName;
    };
  };
}
