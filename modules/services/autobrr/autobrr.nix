{ ... }:
{
  flake.modules.nixos.autobrr =
    args@{ config, lib, ... }:
    let
      cfg = config.my.autobrr;
      serviceName = "autobrr";
      localAddr = "127.0.0.1:7474";
      mediaCfg = config.my.media;
    in
    {
      options.my.autobrr.pathSegment = lib.mkOption {
        type = lib.types.str;
        default = "autobrr";
        description = "Path below the apex domain used for autobrr.";
      };

      options.my.host.services.autobrr = lib.mkEnableOption "autobrr IRC/RSS release automation service";
      config = lib.mkIf config.my.host.services.autobrr (
        import ./_autobrr.nix (
          args
          // {
            inherit
              cfg
              localAddr
              mediaCfg
              serviceName
              ;
          }
        )
      );
    };
}
