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
  themeData = import ./_theme-data.nix { inherit selectedBakedTheme; };
  sharedConfig = import ./_shared-config.nix {
    inherit
      inventory
      lib
      pkgs
      vscodePackage
      ;
    themeSettings = themeData.bakedThemeSettings;
  };
  profileData = import ./_profile-data.nix {
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
