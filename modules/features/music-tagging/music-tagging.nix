{ ... }:
{
  flake-file.inputs.demlo = {
    url = "github:sabrsorensen/demlo/v3.8.1";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [
    ./_music-tagging.nix
    ./_beets.nix
    ./_demlo.nix
  ];
}
