{
  flake.modules.nixos.ombi =
    {
      config,
      lib,
      ...
    }:
    let
      bindAddr = "127.0.0.1";
      port = 5000;
      localAddr = "${bindAddr}:${port}";
      serviceName = "ombi";
    in
    {
      my.media.caddy.apexRoutes = [
        ''
          redir /${serviceName} /${serviceName}/
          handle_path /${serviceName}/* {
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
}
