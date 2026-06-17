{
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./kamino/exports.nix
    ./zaphodbeeblebrox/exports.nix
  ];

  flake.lib.laptop = import ./_public.nix { inherit inputs lib; };
}
