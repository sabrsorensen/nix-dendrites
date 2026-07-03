# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "sabrsorensen's Dendritic Nix configurations";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    armory-runtime-nixpkgs.url = "github:NixOS/nixpkgs/752b6a95db93f03d6901304f760bd452b4b7db41";
    codex-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    demlo = {
      url = "github:sabrsorensen/demlo/v3.8.1";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-csshacks = {
      url = "github:MrOtherGuy/firefox-csshacks";
      flake = false;
    };
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/*";
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/*";
    gitignore = {
      url = "github:hyrfilm/gitignore";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "https://flakehub.com/f/nix-community/impermanence/*";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    import-tree.url = "github:vic/import-tree";
    jovian-nixos = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lazyvim = {
      url = "github:pfassina/lazyvim-nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-auto-follow = {
      url = "github:fzakaria/nix-auto-follow";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-secrets = {
      url = "github:sabrsorensen/nix-secrets";
      flake = false;
    };
    nix-work-secrets = {
      url = "git+https://github.com/sabrsorensen/nix-work-secrets.git";
      flake = false;
    };
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
    packages = {
      url = "path:./packages";
      flake = false;
    };
    partyowl84-vscode-theme = {
      url = "github:sabrsorensen/partyowl84-vscode-theme";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
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
}
