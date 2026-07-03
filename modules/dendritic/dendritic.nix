{ inputs, lib, ... }:
{
  # setup of tools for dendritic pattern

  flake-file.inputs = {
    flake-file.url = "github:vic/flake-file";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/*";
    flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/*";
    flake-parts = {
      url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    # Use Determinate's cooled-down Nixpkgs feed as the repo-wide default.
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
  };

  imports = [
    # Also provides flake-file.flakeModules.{default,import-tree}
    inputs.flake-file.flakeModules.dendritic
  ];

  # import all modules recursively with import-tree
  # same as default set by flake-file.flakeModules.dendritic
  flake-file.outputs = ''
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)
  '';

  # set flake.systems
  systems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
}
