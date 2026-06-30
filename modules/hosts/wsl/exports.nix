{
  inputs,
  lib,
  ...
}:
let
  wsl = import ./_registration-builder.nix { inherit inputs lib; };
in
{
  flake.modules.nixos = {
    nixosWsl = {
      imports = [ (import ./nixos-wsl/_nixos-wsl/host.nix { inherit inputs; }) ];
    };
  };

  flake.lib.wsl = wsl;
}
