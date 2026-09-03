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
      options.my.host.services.scrutiny = lib.mkEnableOption "Scrutiny disk monitoring";
      config = lib.mkIf config.my.host.services.scrutiny (
        import ./_scrutiny.nix (args // { inherit cfg; })
      );
    };
}
