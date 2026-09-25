{ ... }:
{
  flake.modules.nixos.kernel = import ./_kernel.nix;
}
