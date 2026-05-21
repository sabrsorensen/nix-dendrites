{
  flake.modules.nixos.homeassistant-proxy =
  {
    ...
  }:
  {
    services = {
      caddy = {
        virtualHosts."homeassistant.{$DOMAIN}" = {
          extraConfig = ''
            reverse_proxy https://homeassistant.{$DOMAIN} {
              header_up Host {host}
            }
          '';
        };
      };
    };
  };
}