{ ... }:
{
  flake.modules.nixos.deskflow =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.deskflow = lib.mkEnableOption "Deskflow";
      config = lib.mkIf config.my.host.features.deskflow (import ./_deskflow.nix { inherit lib pkgs; });
    };
}
