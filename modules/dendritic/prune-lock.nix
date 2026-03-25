{ inputs, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.nix-auto-follow
  ];
}
