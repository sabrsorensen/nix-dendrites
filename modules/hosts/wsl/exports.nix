{
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.nixos-wsl = import ./nixos-wsl/_nixos-wsl/home-manager.nix { inherit inputs; };

  flake.modules.nixos = {
    nixos-wsl-system = import ./nixos-wsl/_nixos-wsl/system.nix { inherit inputs; };
    nixos-wsl-user = ./nixos-wsl/_nixos-wsl/user.nix;
  };

  flake.lib.wsl = import ./_public.nix { inherit inputs lib; };
}
