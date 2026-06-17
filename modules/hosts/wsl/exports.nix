{
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.nixosWslHome = import ./nixos-wsl/_nixos-wsl/home-manager.nix {
    inherit inputs;
  };

  flake.modules.nixos = {
    nixosWsl = {
      imports = [
        (import ./nixos-wsl/_nixos-wsl/system.nix { inherit inputs; })
        ./nixos-wsl/_nixos-wsl/user.nix
      ];
    };
  };

  flake.lib.wsl = import ./_public.nix { inherit inputs lib; };
}
