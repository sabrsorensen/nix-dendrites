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
      cfg = config.my.services.sonarr;
      arr = import ../_arr { inherit lib; };
      bindAddr = "127.0.0.1";
      groupName = "media";
      port = 8989;
      port4k = 8990;
      serviceName = "sonarr";
    in
    {
      options.my.services.sonarr = {
        enable = lib.mkEnableOption "Sonarr media service";

        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = serviceName;
        };
      };

      config = lib.mkIf cfg.enable (
        arr.mkModule {
          inherit serviceName;
          group = groupName;
          routeSpecs = [
            {
              inherit bindAddr port;
              routeName = cfg.pathSegment;
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
              urlbase = "/${cfg.pathSegment}";
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
    };
}
