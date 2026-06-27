{
  config,
  inventory ? { },
  lib,
  packageFlavor,
  pkgs,
  selectedTheme,
  vscodePackage,
  ...
}:
let
  themeData = import ./_theme-data.nix { inherit selectedTheme; };
  sharedConfig = import ./_shared-config.nix {
    inherit
      inventory
      lib
      packageFlavor
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
