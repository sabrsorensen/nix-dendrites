{ ... }:
{
  flake.modules.nixos.deskflow =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.deskflow (import ./_deskflow.nix { inherit lib pkgs; });
}
