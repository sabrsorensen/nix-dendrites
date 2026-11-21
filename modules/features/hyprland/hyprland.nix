{ ... }:
let
  homeModule = import ./_hyprland-home.nix;
  featureModule =
    args@{ config, lib, ... }:
    {
      options.my.features.hyprland = lib.mkEnableOption "Hyprland user configuration";
      config = lib.mkIf config.my.features.hyprland (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.hyprland = featureModule;

  flake.modules.nixos.hyprland =
    args@{ config, lib, ... }:
    {
      options.my.host.features.hyprland = lib.mkEnableOption "the Hyprland Wayland compositor session";
      config = lib.mkIf config.my.host.features.hyprland (import ./_hyprland-nixos.nix args);
    };
}
