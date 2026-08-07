{ cfg, ... }:
{
  services.flaresolverr = {
    enable = true;
    inherit (cfg) openFirewall package port;
  };
}
