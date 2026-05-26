{
  flake.modules.nixos.ombi =
  {
    config,
    lib,
    ...
  }:
  let
    groupName = "media";
    bindAddr = "127.0.0.1";
    port = 5000;
    localAddr = "${bindAddr}:${port}";
    serviceName = "ombi";
  in
  {
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            redir /${serviceName} /${serviceName}/
            handle_path /${serviceName}/* {
              reverse_proxy ${localAddr}
            }
          '';
        };
      };

      ombi = {
        enable = true;
        openFirewall = true;
        port = port;
      };
    };
  };
}