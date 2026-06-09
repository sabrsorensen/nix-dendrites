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

  imports = lib.optionals (inputs ? nixos-wsl && inputs ? nix-work-secrets) [ ./_wsl.nix ];
}
