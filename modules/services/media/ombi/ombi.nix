{
  flake.modules.nixos.ombi =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.ombi;
      bindAddr = "127.0.0.1";
      port = 5000;
      localAddr = "${bindAddr}:${lib.toString port}";
      serviceName = "ombi";
    in
    {
      options.my.services.ombi = {
        enable = lib.mkEnableOption "Ombi media service";

        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = serviceName;
        };
      };

      config = lib.mkIf cfg.enable {
        my.caddy.apexRoutes = [
          ''
            redir /${cfg.pathSegment} /${cfg.pathSegment}/
            handle_path /${cfg.pathSegment}/* {
              reverse_proxy ${localAddr}
            }
          ''
        ];

        services.ombi = {
          enable = true;
          openFirewall = false;
          port = port;
        };
      };
    };
}
