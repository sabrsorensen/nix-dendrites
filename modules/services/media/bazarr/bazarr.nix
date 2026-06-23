{ ... }:
{
  flake.modules.nixos.bazarr =
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
      port = 6767;
      port4k = 6768;
      serviceName = "bazarr";
    in
    lib.mkIf config.my.media.enable (
      arr.mkModule {
        inherit serviceName;
        group = groupName;
        routeSpecs = [
          {
            inherit bindAddr port;
            marker = "</head>";
          }
          {
            inherit bindAddr;
            port = port4k;
            marker = "</head>";
            pathSuffix = "4k";
          }
        ];
        serviceConfig = {
          enable = true;
          openFirewall = false;
          listenPort = port;
          group = groupName;
        };
        managedServices."${serviceName}4k" = arr.mkManagedService {
          description = "Bazarr 4K";
          execStart = "${pkgs.bazarr}/bin/bazarr -c=/var/lib/bazarr4k --port=${lib.toString port4k}";
          user = serviceName;
          group = groupName;
          extraServiceConfig.KillSignal = "SIGINT";
        };
      }
    );
}
