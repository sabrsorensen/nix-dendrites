{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.codex-nix = {
    url = "github:sadjow/codex-cli-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = lib.optional (inputs ? codex-nix) ./_codex.nix;
}
