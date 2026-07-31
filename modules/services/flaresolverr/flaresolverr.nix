{ ... }:
{
  flake.modules.nixos.flaresolverr =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.flaresolverr;
    in
    {
      options.my.flaresolverr = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 8191;
          description = "Local port used by FlareSolverr.";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.flaresolverr;
          description = "FlareSolverr package to run.";
        };
        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Expose FlareSolverr beyond local media consumers.";
        };
      };

      config = lib.mkIf config.my.host.services.flaresolverr (
        import ./_content.nix (args // { inherit cfg; })
      );
    };
}
