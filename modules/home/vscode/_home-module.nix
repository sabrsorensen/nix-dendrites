{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.editor;
  vscodeTheme = "partyowl84";
  vscodePkgs = pkgs.extend inputs.nix4vscode.overlays.forVscode;
  package = import ./package/_package.nix {
    inherit
      config
      cfg
      inputs
      lib
      vscodeTheme
      ;
    pkgs = vscodePkgs;
  };
  editorProgram = import ./_vscode-profiles.nix {
    inherit cfg lib vscodeTheme;
    pkgs = vscodePkgs;
    inherit (package) baseThemePackage themePackage;
  };
in
{
  options.my.editor = import ./_vscode-options.nix { inherit lib; };
  config = lib.mkIf config.my.features.vscode (
    import ./_vscode.nix {
      inherit cfg editorProgram lib;
      pkgs = vscodePkgs;
    }
  );
}
