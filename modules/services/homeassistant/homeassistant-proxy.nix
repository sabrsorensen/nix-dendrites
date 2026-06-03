{
  flake.modules.nixos.homeassistant-proxy =
    {
      ...
    }:
    {
      my.caddy.virtualHosts."homeassistant.{$DOMAIN}".routes = [
        ''
          reverse_proxy https://homeassistant.{$DOMAIN} {
            header_up Host {host}
          }
        ''
      ];
    };
}
