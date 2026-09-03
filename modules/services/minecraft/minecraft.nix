{ ... }:
{
  flake.modules.nixos.minecraft =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.services.minecraft = lib.mkEnableOption "Minecraft server";
      config = lib.mkIf config.my.host.services.minecraft (import ./_minecraft.nix args);
    };
}
