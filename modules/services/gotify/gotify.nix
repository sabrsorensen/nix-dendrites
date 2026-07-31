{ ... }:
{
  flake.modules.nixos.gotify =
    args@{ config, lib, ... }:
    let
      cfg = config.my.gotify;
      pathSegment = cfg.pathSegment;
    in
    {
      options.my.gotify = {
        pathSegment = lib.mkOption {
          type = lib.types.str;
          default = "gotify";
          description = "Path below the apex domain used for Gotify.";
        };
        allowRegistrations = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Allow Gotify users to register themselves.";
        };
      };

      config = lib.mkIf config.my.host.services.gotify (
        import ./_content.nix (args // { inherit cfg pathSegment; })
      );
    };
}
