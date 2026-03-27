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
    overlays.default =
      final: prev:
      (inputs.nix4vscode.overlays.forVscode final prev)
      // (if inputs ? decky-packages then inputs.decky-packages.overlays.default final prev else { })
      // {
        local = withSystem prev.stdenv.hostPlatform.system ({ config, ... }: config.packages);
        vscode-partyowl84 =
          inputs.partyowl84-vscode-theme.packages.${prev.stdenv.hostPlatform.system}.vscode-partyowl84;
        vscode-synthwave-blues =
          inputs.synthwave-blues-vscode-theme.packages.${prev.stdenv.hostPlatform.system}.vscode-synthwave-blues;
        vscode-synthwave-84 =
          inputs.synthwave-84-vscode-theme.packages.${prev.stdenv.hostPlatform.system}.vscode-synthwave84;
      };
  };

}
