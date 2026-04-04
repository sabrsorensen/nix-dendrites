{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos."NixOS-WSL" = {
    imports = [
      (import ./_nixos-wsl/system.nix { inherit inputs; })
      ./_nixos-wsl/user.nix
      (import ./_nixos-wsl/home-defaults.nix { inherit inputs lib; })
    ];
  };

  flake.modules.homeManager."NixOS-WSL" = import ./_nixos-wsl/home-manager.nix { inherit inputs; };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "NixOS-WSL";
}
