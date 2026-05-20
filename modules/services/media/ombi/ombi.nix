{
  flake.modules.nixos.ombi =
  {
    config,
    lib,
    ...
  }:
  {
    services = {
      caddy = {
        virtualHosts."{$DOMAIN}" = {
          extraConfig = ''
            redir /ombi /ombi/
            handle_path /ombi/* {
              reverse_proxy 127.0.0.1:${lib.toString config.services.ombi.port}
            }
          '';
        };
      };

      ombi = {
        enable = true;
        openFirewall = true;
      };
    };
  };
}