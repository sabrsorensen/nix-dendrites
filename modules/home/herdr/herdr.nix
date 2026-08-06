{ inputs, ... }:
let
  homeModule = { pkgs, ... }@args: import ./_home-content.nix (args // { inherit inputs; });
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.herdr = lib.mkEnableOption "Herdr";
      config = lib.mkIf config.my.features.herdr (homeModule args);
    };
  nixosModule = import ./_nixos-content.nix;
in
{
  flake-file.inputs.herdr-nix = {
    url = "github:herdrdev/herdr-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.herdr = featureModule;

  flake.modules.nixos.home-herdr =
    args@{
      config,
      lib,
      ...
    }:
    let
      host = config.my.host;
    in
    lib.mkIf (host.platform == "wsl" && host.home.enable) (nixosModule args);
}
