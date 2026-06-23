{
  flake.modules.nixos.flaresolverr =
    {
      config,
      lib,
      ...
    }:
    {
      config = lib.mkIf config.my.media.enable {
        services = {
          flaresolverr = {
            enable = true;
            openFirewall = true;
          };
        };
      };
    };
}
