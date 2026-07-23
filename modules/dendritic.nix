{ inputs, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.flake-file.flakeModules.nix-auto-follow
  ];

  flake-file.inputs = {
    armory-runtime-nixpkgs.url = "github:NixOS/nixpkgs/752b6a95db93f03d6901304f760bd452b4b7db41";
    codex-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    demlo = {
      url = "github:sabrsorensen/demlo/v3.8.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/*";
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/*";
    firefox-csshacks = {
      url = "github:MrOtherGuy/firefox-csshacks";
      flake = false;
    };
    gitignore = {
      url = "github:hyrfilm/gitignore";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jovian-nixos = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "https://flakehub.com/f/nix-community/impermanence/*";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lazyvim = {
      url = "github:pfassina/lazyvim-nix";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-auto-follow = {
      url = "github:fzakaria/nix-auto-follow";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
    partyowl84-vscode-theme = {
      url = "github:sabrsorensen/partyowl84-vscode-theme";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-secrets = {
      url = "github:sabrsorensen/nix-secrets";
      flake = false;
    };
    nix-work-secrets = {
      url = "git+https://github.com/sabrsorensen/nix-work-secrets.git";
      flake = false;
    };
    sops-nix = {
      url = "https://flakehub.com/f/Mic92/sops-nix/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    synthwave-84-vscode-theme = {
      url = "github:sabrsorensen/nix-synthwave-vscode";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    synthwave-blues-vscode-theme = {
      url = "github:sabrsorensen/synthwave-blues-vscode-theme";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    treefmt-nix = {
      url = "https://flakehub.com/f/numtide/treefmt-nix/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake-file.outputs = ''
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)
  '';

  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
}
