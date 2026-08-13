{ ... }:
{
  flake.modules.nixos.wine =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.wine = lib.mkEnableOption "Wine";
      config = lib.mkIf config.my.host.features.wine (import ./_wine.nix args);
    };
}
