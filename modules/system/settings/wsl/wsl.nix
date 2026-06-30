{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs = {
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-work-secrets = {
      url = "git+https://github.com/sabrsorensen/nix-work-secrets.git";
      flake = false;
    };
  };

  flake.modules.nixos.wsl-base = lib.mkIf (inputs ? nixos-wsl && inputs ? nix-work-secrets) {
    imports = [
      inputs.nixos-wsl.nixosModules.wsl
      ./_base-module.nix
      (import ./_certs-module.nix { inherit inputs lib; })
    ];
  };
}
