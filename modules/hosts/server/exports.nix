{
  inputs,
  lib,
  ...
}:
{
  flake.lib.server = import ./_public.nix { inherit inputs lib; };
}
