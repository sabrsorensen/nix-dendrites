{ ... }:
{
  flake.modules.nixos.minecraft-tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.minecraft (import ./_minecraft.nix { inherit pkgs; });
}
