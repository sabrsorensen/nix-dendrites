{ ... }:
{
  flake.modules.nixos.wsl-fish =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.platform == "wsl" && config.my.host.home.enable) {
      home-manager.users.ssorensen.programs.fish = {
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
        interactiveShellInit = ''
          if command -sq gpg
            set -gx GPG_TTY (tty)
          end
        '';
        functions = {
          ls = "command ls -la --color=auto $argv";
          # Keep the managed Fish greeting available in the work profile.
          fish_greeting = ''
            if not command -sq fortune
              echo "Install fortune"
            end
            if not command -sq cowsay
              echo "Install cowsay"
            end
            if not command -sq lolcat
              echo "Install lolcat"
            end
            set -l toon (random choice {default,bud-frogs,dragon,dragon-and-cow,elephant,moose,stegosaurus,tux,vader})
            if command -sq lolcat
              fortune -s | cowsay -f $toon | lolcat
            else if command -sq fortune
              fortune -s | cowsay -f $toon
            else
              echo "Something fishy going on around here ..."
            end
          '';
          inhibitSleep = ''
            echo "🔒 Inhibiting sleep for: $argv"
            echo -ne "\033]0;$argv\007"
            systemd-inhibit --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who="$USER" --why=nixos-rebuild --mode=block $argv
          '';
          editorSyncWindows = "editor-sync-windows $argv";
          esw = "editorSyncWindows $argv";
          editorSyncWindowsExtensions = "editor-sync-windows --install-extensions $argv";
          eswe = "editorSyncWindowsExtensions $argv";
          choco = "choco.exe $argv";
          wsl = "wsl.exe $argv";
          cleanGenerations = ''
            nix-collect-garbage -d
            or return $status
            sudo nix-collect-garbage -d
            or return $status
            sudo nix store gc
            or return $status
            sudo nix store optimise
          '';
        };
      };
    };
}
