{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs = {
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-secrets = {
      url = "git+https://github.com/sabrsorensen/nix-secrets.git";
      flake = false;
    };
  };

  imports = lib.optional (inputs ? sops-nix) ./_secrets.nix;
}
