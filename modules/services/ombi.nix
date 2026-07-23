{ ... }:
{
  flake.modules.nixos.ombi =
    { config, lib, ... }:
    let
      cfg = config.my.ombi;
      port = 5000;
    in
    {
      options.my.ombi.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "ombi";
        description = "Path below the apex domain used for Ombi.";
      };

      config = lib.mkIf config.my.host.services.ombi {
        my.caddy.apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            handle_path /${cfg.pathSegment}/* {
              reverse_proxy 127.0.0.1:${toString port}
            }
          ''
        ];

        services.ombi = {
          enable = true;
          openFirewall = false;
          inherit port;
        };
      };
    };
}
