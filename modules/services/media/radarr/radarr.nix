{ ... }:
{
  flake.modules.nixos.radarr =
    {
      lib,
      pkgs,
      ...
    }:
    let
      arr = import ../_arr { inherit lib; };
      bindAddr = "127.0.0.1";
      groupName = "media";
      port = 7878;
      port4k = 7879;
      serviceName = "radarr";
    in
    arr.mkModule {
      inherit serviceName;
      group = groupName;
      routeSpecs = [
        {
          inherit bindAddr port;
        }
        {
          inherit bindAddr;
          port = port4k;
          pathSuffix = "4k";
        }
      ];
      serviceConfig = {
        enable = true;
        openFirewall = false;
        group = groupName;
        settings.server = {
          urlbase = "/${serviceName}";
          inherit port;
          bindaddress = bindAddr;
        };
      };
      managedServices.radarr4k = arr.mkManagedService {
        description = "Radarr 4K";
        execStart = "${pkgs.radarr}/bin/Radarr -nobrowser -data=/var/lib/radarr4k";
        user = serviceName;
        group = groupName;
      };
    };
}
