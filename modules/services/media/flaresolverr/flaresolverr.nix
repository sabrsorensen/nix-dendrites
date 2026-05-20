{
  flake.modules.nixos.flaresolverr =
  {
    config,
    lib,
    ...
  }:
  {
    services = {
      flaresolverr = {
        enable = true;
        openFirewall = true;
      };
    };
  };
}