{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  homePackages = config.home-manager.users.${username}.home.packages or [ ];
in
{
  home-manager.users.${username}.home.persistence."/persistent" = {
    directories = [
      ".config/fish"
      ".config/mozilla/firefox"
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
