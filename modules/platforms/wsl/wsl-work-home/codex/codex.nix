{ inputs, ... }:
{
  flake-file.inputs.codex-nix = {
    url = "github:sadjow/codex-cli-nix";
    inputs.flake-utils.follows = "flake-utils";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [ (import ./_content.nix { inherit inputs; }) ];
}
