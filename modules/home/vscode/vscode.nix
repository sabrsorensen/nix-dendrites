{ inputs, ... }:
let
  homeModule = import ./_home-module.nix { inherit inputs; };
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.vscode = lib.mkEnableOption "VS Code";
      imports = [ homeModule ];
    };
  wslVscodeModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.wslVscode = lib.mkEnableOption "WSL VS Code synchronization";
      config = lib.mkIf config.my.features.wslVscode (
        import ./wsl-vscode/_content.nix (args // { inherit inputs pkgs; })
      );
    };
in
{
  flake-file.inputs = {
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    partyowl84-vscode-theme = {
      url = "github:sabrsorensen/partyowl84-vscode-theme";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    synthwave-84-vscode-theme = {
      url = "github:sabrsorensen/nix-synthwave-vscode";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    synthwave-blues-vscode-theme = {
      url = "github:sabrsorensen/synthwave-blues-vscode-theme";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  dendritic.homeManagerModules = [
    featureModule
    wslVscodeModule
  ];
  flake.modules.homeManager.vscode = featureModule;

  flake.modules.homeManager.wsl-vscode = wslVscodeModule;
}
