{ inputs, ... }:
{
  flake-file.inputs = {
    firefox-csshacks = {
      url = "github:MrOtherGuy/firefox-csshacks";
      flake = false;
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  imports = [ (import ./_firefox.nix { inherit inputs; }) ];
}
