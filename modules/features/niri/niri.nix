{ ... }:
let
  homeModule = import ./_niri-home.nix;
  featureModule =
    args@{ config, lib, ... }:
    {
      options.my.features.niri = lib.mkEnableOption "niri user configuration";
      config = lib.mkIf config.my.features.niri (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.niri = featureModule;

  flake.modules.nixos.niri =
    args@{ config, lib, ... }:
    {
      options.my.host.features.niri =
        lib.mkEnableOption "the niri scrollable-tiling Wayland compositor session";
      config = lib.mkIf config.my.host.features.niri (import ./_niri-nixos.nix args);
    };
}
