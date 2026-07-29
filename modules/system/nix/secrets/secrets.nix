{ inputs, lib, ... }:
{
  flake-file.inputs = {
    sops-nix = {
      url = "https://flakehub.com/f/Mic92/sops-nix/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-secrets = {
      url = "github:sabrsorensen/nix-secrets";
      flake = false;
    };
  };

  imports = lib.optional (inputs ? sops-nix) ./_secrets.nix;
}
