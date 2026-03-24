{ inputs, lib, ... }:
{
  flake-file.inputs = {
    treefmt-nix = {
      url = lib.mkDefault "github:numtide/treefmt-nix";
      #inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Bootstrap safely: declare the input first, and only import the consumer
  # module once the current root flake already provides it. The consumer file
  # lives under `/_...` so import-tree ignores it until we import it manually.
  imports = lib.optional (inputs ? treefmt-nix) ./_formatter.nix;
}
