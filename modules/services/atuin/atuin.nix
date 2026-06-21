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
      serviceName = "atuin";
    in
    {
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
}