{ ... }:
{
  flake.modules.nixos.minecraft-tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.minecraft = lib.mkEnableOption "Minecraft tooling";
      config = lib.mkIf config.my.host.features.minecraft (import ./_minecraft.nix { inherit pkgs; });
    };
}
