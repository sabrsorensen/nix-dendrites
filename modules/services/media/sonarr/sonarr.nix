{
  flake.modules.nixos.sonarr =
    {
      lib,
      pkgs,
      ...
    }:
    let
      arr = import ../_arr/lib.nix { inherit lib; };
      bindAddr = "127.0.0.1";
      groupName = "media";
      port = 8989;
      port4k = 8990;
      localAddr = "${bindAddr}:${lib.toString port}";
      localAddr4k = "${bindAddr}:${lib.toString port4k}";
      serviceName = "sonarr";
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

      services.sonarr = {
        enable = true;
        openFirewall = false;
        group = groupName;
        settings.server = {
          urlbase = "/${serviceName}";
          port = port;
          bindaddress = "127.0.0.1";
        };
      };

      users.users.${serviceName}.group = groupName;
      systemd.services.sonarr4k = arr.mkManagedService {
        description = "Sonarr 4K";
        execStart = "${pkgs.sonarr}/bin/Sonarr -nobrowser -data=/var/lib/sonarr4k/";
        user = serviceName;
        group = groupName;
      };
    };
}
