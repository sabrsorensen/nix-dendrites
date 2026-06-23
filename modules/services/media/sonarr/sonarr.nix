{ ... }:
{
  flake.modules.nixos.sonarr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      arr = import ../_arr { inherit lib; };
      bindAddr = "127.0.0.1";
      groupName = "media";
      port = 8989;
      port4k = 8990;
      serviceName = "sonarr";
    in
    lib.mkIf config.my.media.enable (
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
        managedServices.sonarr4k = arr.mkManagedService {
          description = "Sonarr 4K";
          execStart = "${pkgs.sonarr}/bin/Sonarr -nobrowser -data=/var/lib/sonarr4k/";
          user = serviceName;
          group = groupName;
        };
      }
    );
}
