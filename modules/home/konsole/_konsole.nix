{ pkgs, ... }:
let
  nightOwl = pkgs.fetchFromGitHub {
    owner = "yijiem";
    repo = "konsole-night-owl-theme";
    rev = "main";
    sha256 = "sha256-OxoH+Z50MbnhAmaLO9EO+gfzDqj6YUWLlM+oz92Wuio=";
  };
in
{
  home.file.".local/share/konsole/NightOwl.colorscheme".source = "${nightOwl}/NightOwl.colorscheme";
}
