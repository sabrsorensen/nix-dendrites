{
  config,
  inventory ? { },
  lib,
  pkgs,
  selectedBakedTheme,
  vscodePackage,
  ...
}:
let
  themeData = import ./vscode-theme-data.nix { inherit selectedBakedTheme; };
  sharedConfig = import ./vscode-shared-config.nix {
    inherit
      inventory
      lib
      pkgs
      vscodePackage
      ;
    themeSettings = themeData.bakedThemeSettings;
  };
  profileData = import ./vscode-profile-data.nix {
    inherit config pkgs;
  };
in
{
  inherit (profileData)
    cSharpExts
    dotnetSettings
    gitHubExts
    higiExts
    higiSettings
    nixSettings
    pythonExts
    pythonSettings
    sqlExts
    ;
  inherit (sharedConfig)
    defaultExts
    defaultKeyBindings
    defaultProfileOnlySettings
    defaultUserSettings
    mkExtensions
    windowsTerminalSettings
    ;
}
