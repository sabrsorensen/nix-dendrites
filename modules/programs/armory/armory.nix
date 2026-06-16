{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.armory-runtime-nixpkgs = {
    url = "github:NixOS/nixpkgs/752b6a95db93f03d6901304f760bd452b4b7db41";
  };

  imports = lib.optional (inputs ? armory-runtime-nixpkgs) ./_armory.nix;
}
