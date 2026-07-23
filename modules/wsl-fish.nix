{ ... }:
{
  flake.modules.nixos.wsl-fish =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.roles.wsl (
      let
        flakePath = config.my.deployment.localFlakePath;
      in
      {
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
            # Retain the predecessor greeting rather than silently dropping the
            # managed Fish function when the work profile was split out.
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
          }
          // lib.optionalAttrs (flakePath != null) {
            # Local switching is independent of remote-deployment permission.
            # The predecessor enabled these on WSL from its derived local path.
            nhSwitch = ''
              if test (count $argv) -ge 1; and contains -- $argv[1] -j --max-jobs
                nh os switch ${flakePath} --keep-going -- $argv
              else
                nh os switch ${flakePath} --keep-going $argv
              end
            '';
            nhs = "nhSwitch";
            nhSwitchUpgrade = ''
              if not test -d ${flakePath}
                echo "Local flake path does not exist: ${flakePath}"
                return 1
              end
              pushd ${flakePath} >/dev/null
              or return $status
              nix flake update
              set update_status $status
              if test $update_status -eq 0
                set max_passes 10
                for pass in (seq $max_passes)
                  set before_state (sha256sum flake.nix flake.lock 2>/dev/null | string collect)
                  nix run .#write-flake
                  set update_status $status
                  if test $update_status -ne 0
                    break
                  end
                  set after_state (sha256sum flake.nix flake.lock 2>/dev/null | string collect)
                  if test "$before_state" = "$after_state"
                    break
                  end
                  if test $pass -eq $max_passes
                    echo "write-flake did not settle after $max_passes passes"
                    set update_status 1
                  end
                end
              end
              popd >/dev/null
              if test $update_status -ne 0
                return $update_status
              end
              nhSwitch $argv
            '';
            nhsu = "nhSwitchUpgrade";
          };
        };
      }
    );
}
