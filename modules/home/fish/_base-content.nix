{
  isWsl,
  lib,
  pkgs,
  ...
}:
{
  enable = true;
  generateCompletions = true;
  plugins = [
    {
      name = "fish-ssh-agent";
      src = pkgs.fetchFromGitHub {
        owner = "danhper";
        repo = "fish-ssh-agent";
        rev = "f10d95775352931796fd17f54e6bf2f910163d1b";
        hash = "sha256-cFroQ7PSBZ5BhXzZEKTKHnEAuEu8W9rFrGZAb8vTgIE=";
      };
    }
    {
      name = "to-fish";
      src = pkgs.fetchFromGitHub {
        owner = "joehillen";
        repo = "to-fish";
        rev = "b94c2e5756b4646051fe64ad8cd36eda33405f8a";
        hash = "sha256-jQGYFON13XhjX+Xrnd8kglco8xRJ9G7kkGmswtuEgZw=";
      };
    }
  ];
  interactiveShellInit = lib.mkIf (!isWsl) ''
    if command -sq gpg
      set -gx GPG_TTY (tty)
    end
  '';
}
