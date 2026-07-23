{ ... }:
{
  flake.modules.nixos.konsole =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = if config.my.host.roles.wsl then "ssorensen" else "sam";
      nightOwl = pkgs.fetchFromGitHub {
        owner = "yijiem";
        repo = "konsole-night-owl-theme";
        rev = "main";
        sha256 = "sha256-OxoH+Z50MbnhAmaLO9EO+gfzDqj6YUWLlM+oz92Wuio=";
      };
    in
    lib.mkIf config.my.host.features.gui {
      home-manager.users.${username}.home.file.".local/share/konsole/NightOwl.colorscheme".source =
        "${nightOwl}/NightOwl.colorscheme";
    };
}
