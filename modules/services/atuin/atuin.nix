{
  inputs,
  ...
}:
{
  flake.modules.nixos.atuin-server =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.atuin;
      serviceName = "atuin";
    in
    {
      options.my.services.atuin.enable = lib.mkEnableOption "Atuin server service";

      config = lib.mkIf cfg.enable {
        my.media.caddy.apexRoutes = [
          ''
            redir /${serviceName} /${serviceName}/
            reverse_proxy /${serviceName}/* ${config.services.atuin.host}:${lib.toString config.services.atuin.port}
          ''
        ];

        services.atuin = {
          enable = true;
          port = 8888; # default
          host = "127.0.0.1";
          openFirewall = true;
          openRegistration = false;
          path = "/${serviceName}/";
        };
      };
    };
}
