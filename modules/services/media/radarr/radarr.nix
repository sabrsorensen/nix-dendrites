{ ... }:
{
  flake.modules.nixos.radarr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.radarr;
      arr = import ../_arr { inherit lib; };
      bindAddr = "127.0.0.1";
      groupName = "media";
      port = 7878;
      port4k = 7879;
      serviceName = "radarr";
    in
    {
      options.my.services.radarr = {
        enable = lib.mkEnableOption "Radarr media service";

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
          managedServices.radarr4k = arr.mkManagedService {
            description = "Radarr 4K";
            execStart = "${pkgs.radarr}/bin/Radarr -nobrowser -data=/var/lib/radarr4k";
            user = serviceName;
            group = groupName;
          };
        }
      );
    };
}
