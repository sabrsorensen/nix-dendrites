{
  inputs,
  lib,
  ...
}:
{
  flake.lib.rpi = import ./_public.nix { inherit inputs lib; };
  flake.modules.nixos.rpi-base = ./_rpi/base.nix;
}
