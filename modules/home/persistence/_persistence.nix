{
  config,
  lib,
  pkgs,
  ...
}:
let
  homePackages = config.home.packages;
in
{
  home.persistence."/persistent" = {
    directories = [
      ".config/fish"
    ]
    ++ lib.optionals (lib.elem pkgs.google-chrome homePackages) [
      ".config/Google-Chrome"
    ]
    ++ lib.optionals (lib.elem pkgs.chromium homePackages) [
      ".config/chromium"
    ];
    files = [ ".bash_history" ];
  };
}
