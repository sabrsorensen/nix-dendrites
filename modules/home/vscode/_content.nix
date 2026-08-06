{
  lib,
  pkgs,
  cfg,
  editorProgram,
  ...
}:
{
  home.packages =
    lib.optionals cfg.installLocalDotnetSdk [ pkgs.dotnetCorePackages.sdk_10_0-bin ]
    ++ lib.optionals cfg.profiles.stm32 [ pkgs.stm32cubemx ];
  programs =
    lib.optionalAttrs (cfg.packageFlavor == "vscode") { vscode = editorProgram; }
    // lib.optionalAttrs (cfg.packageFlavor == "vscodium") { vscodium = editorProgram; };
}
