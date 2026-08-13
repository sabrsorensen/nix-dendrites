{ inputs, ... }:
let
  homeModule = import ./_firefox.nix { inherit inputs; };
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.firefox = lib.mkEnableOption "Firefox";
      config = lib.mkIf config.my.features.firefox (homeModule args);
    };
in
{
  flake-file.inputs = {
    firefox-csshacks = {
      url = "github:MrOtherGuy/firefox-csshacks";
      flake = false;
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  perSystem = import ./firefox-addons/_updater.nix { inherit inputs; };

  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.firefox = featureModule;

  flake.modules.nixos.firefox =
    { lib, ... }:
    {
      options.my.host.features.firefox = lib.mkEnableOption "Firefox browser profile";
    };
}
