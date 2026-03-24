{
  inputs,
  lib,
  withSystem,
  ...
}:
{
  flake-file.inputs = {
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    packages = {
      url = "path:./packages";
      flake = false;
    };
  };

  imports = lib.optional (inputs ? pkgs-by-name-for-flake-parts) ./_pkgs-by-name.nix;

  flake = {
    overlays.default = _final: prev: {
      local = withSystem prev.stdenv.hostPlatform.system ({ config, ... }: config.packages);
    };
  };

}
