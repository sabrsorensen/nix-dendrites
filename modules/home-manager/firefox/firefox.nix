{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs = {
    firefox-csshacks = {
      url = "github:MrOtherGuy/firefox-csshacks";
      flake = false;
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  imports = lib.optional (inputs ? firefox-csshacks && inputs ? nur) ./_firefox.nix;
}
