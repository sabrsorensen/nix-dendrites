{ ... }:
{
  flake.modules.nixos.scrutiny =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.scrutiny;
    in
    {
      options.my.scrutiny.hostName = lib.mkOption {
        type = lib.types.str;
        default = "scrutiny";
      };
      config = lib.mkIf config.my.host.services.scrutiny (
        import ./_content.nix (args // { inherit cfg; })
      );
    };
}
