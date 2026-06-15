{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.gitignore = {
    url = "github:hyrfilm/gitignore";
    flake = false;
  };

  imports = lib.optional (inputs ? gitignore) ./_git.nix;
}
