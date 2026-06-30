{ ... }:
{
  flake.modules.nixos.prowlarr =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.prowlarr;
      arr = import ../_arr { inherit lib; };
      bindAddr = "127.0.0.1";
      port = 9696;
      serviceName = "prowlarr";
    in
    {
      options.my.services.prowlarr = {
        enable = lib.mkEnableOption "Prowlarr media service";

        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = serviceName;
        };
      };

      config = lib.mkIf cfg.enable (
        arr.mkModule {
          inherit serviceName;
          setUserGroup = false;
          routeSpecs = [
            {
              inherit bindAddr port;
              routeName = cfg.pathSegment;
            }
          ];
          serviceConfig = {
            enable = true;
            openFirewall = false;
            settings.server = {
              urlbase = "/${cfg.pathSegment}";
              inherit port;
              bindaddress = bindAddr;
            };
          };
        }
      );
    };
}
