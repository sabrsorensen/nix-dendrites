# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "sabrsorensen's Dendritic Nix configurations";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    import-tree.url = "github:vic/import-tree";
    nix-auto-follow = {
      url = "github:fzakaria/nix-auto-follow";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-secrets = {
      url = "github:sabrsorensen/nix-secrets";
      flake = false;
    };
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-lib.follows = "nixpkgs";
    packages = {
      url = "path:./packages";
      flake = false;
    };
    partyowl84-vscode-theme = {
      url = "github:sabrsorensen/partyowl84-vscode-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    synthwave-84-vscode-theme = {
      url = "github:sabrsorensen/nix-synthwave-vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    synthwave-blues-vscode-theme = {
      url = "github:sabrsorensen/synthwave-blues-vscode-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
}
