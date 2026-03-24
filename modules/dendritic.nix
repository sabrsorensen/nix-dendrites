{ inputs, lib, ... }:
{
  # setup of tools for dendritic pattern

  flake-file.inputs = {
    flake-file.url = "github:vic/flake-file";
    # Override the channels URL for more consistency with other flakes
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
