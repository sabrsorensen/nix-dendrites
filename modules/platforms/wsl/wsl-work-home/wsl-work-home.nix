{ ... }:
let
  homeModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.wslWorkHome = lib.mkEnableOption "WSL work Home Manager profile";
      config = lib.mkIf config.my.features.wslWorkHome (import ./_wsl-work-home.nix args);
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.wsl-work-home = homeModule;

  # The private work input supplies the SOPS secret declarations.  This module
  # owns only the portable WSL work tooling and is safe on every other host.
  flake.modules.nixos.wsl-work-home =
    { config, lib, ... }:
    lib.mkIf (config.my.host.platform == "wsl" && config.my.host.home.enable) {
      # fabric declares invoke<3 and nixpkgs marks it broken against invoke 3,
      # but azure-cli depends on fabric. paramiko also propagates invoke, and
      # the Python closure can only hold one version, so pin it for the whole
      # package set rather than for fabric alone.
      nixpkgs.overlays = [
        (_: prev: {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (pyFinal: pyPrev: {
              invoke = pyPrev.invoke.overridePythonAttrs (_: rec {
                version = "2.2.1";
                src = pyFinal.fetchPypi {
                  pname = "invoke";
                  inherit version;
                  hash = "sha256-UVv0m0pIkyt5sCRZA0jaIvOcSULf+ZGtH7i4uuob5wc=";
                };
              });
            })
          ];
        })
      ];
      warnings = [
        ''
          python3Packages.invoke is pinned to 2.2.1 on WSL because fabric
          declares invoke<3 and azure-cli depends on it (fabric/fabric#2376).
          Remove the overlay in
          modules/platforms/wsl/wsl-work-home/wsl-work-home.nix once nixpkgs
          no longer marks fabric broken on invoke 3 -- check with:
            grep -n broken "$(nix eval --raw .#nixosConfigurations.nixos-wsl.pkgs.path)/pkgs/development/python-modules/fabric/default.nix"
        ''
      ];
    };
}
