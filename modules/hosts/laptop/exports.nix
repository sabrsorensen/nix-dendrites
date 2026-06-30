{
  inputs,
  lib,
  ...
}:
let
  laptop = import ./_registration-builder.nix { inherit inputs lib; };
in
{
  imports = [
    ./kamino/exports.nix
    ./zaphodbeeblebrox/exports.nix
  ];

  flake.lib.laptop = laptop;
}
