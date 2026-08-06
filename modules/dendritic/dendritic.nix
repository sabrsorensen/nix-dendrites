{ inputs, lib, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.flake-file.flakeModules.nix-auto-follow
  ];

  options.dendritic.homeManagerModules = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ];
    internal = true;
    description = "Home Manager feature modules broadcast to managed users.";
  };

  config = {
    flake-file.inputs = {
      # Bootstrap inputs stay together in the Dendritic module. Feature
      # integrations declare their own dependencies alongside their consumers.
      flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/*";
      flake-file.url = "github:vic/flake-file";
      flake-parts = {
        url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
        inputs.nixpkgs-lib.follows = "nixpkgs";
      };
      flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/*";
      nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
    };

    flake-file.outputs = ''
      inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)
    '';

    flake-file.description = "sabrsorensen's Dendritic Nix configurations";

    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
}
