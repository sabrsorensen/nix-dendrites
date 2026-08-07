{
  baseThemePackage,
  cfg,
  lib,
  pkgs,
  themePackage,
  vscodeTheme,
  ...
}:
let
  extensions = import ./_vscode-extensions.nix {
    inherit
      baseThemePackage
      cfg
      pkgs
      ;
  };
  settings = import ./_vscode-settings.nix { inherit vscodeTheme; };
in
{
  enable = true;
  package = themePackage;
  profiles.default = {
    enableExtensionUpdateCheck = true;
    enableUpdateCheck = true;
    extensions = extensions.defaultExtensions;
    enableMcpIntegration = true;
    keybindings = settings.defaultKeybindings;
    userSettings = settings.defaultProfileUserSettings;
  };
  profiles = {
    Higi_LLP =
      if cfg.profiles.higiLlp then
        {
          extensions = extensions.higiExtensions;
          enableMcpIntegration = true;
          keybindings = settings.defaultKeybindings;
          userSettings = settings.mkHigiUserSettings { runCodexInWsl = cfg.higi.runCodexInWsl; };
        }
      else
        { };
    Nix = {
      extensions = extensions.nixExtensions;
      enableMcpIntegration = true;
      keybindings = settings.defaultKeybindings;
      languageSnippets = settings.nixProfileSnippets;
      userSettings = settings.nixProfileUserSettings;
    };
    Python =
      if cfg.profiles.python then
        {
          extensions = extensions.pythonExtensions;
          enableMcpIntegration = true;
          keybindings = settings.defaultKeybindings;
          userSettings = settings.pythonProfileUserSettings;
        }
      else
        { };
    STM32 =
      if cfg.profiles.stm32 then
        {
          extensions = extensions.stm32Extensions;
          keybindings = settings.defaultKeybindings;
          userSettings = settings.stm32ProfileUserSettings;
        }
      else
        { };
  };
}
