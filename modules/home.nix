{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
  gitValue =
    path: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${inputs.nix-secrets}/${path}");
  gpgKeyFiles = builtins.filter (name: builtins.match ".*\\.asc" name != null) (
    builtins.attrNames (builtins.readDir "${inputs.nix-secrets}/gpg-keys")
  );
  vimNightOwl =
    pkgs:
    pkgs.vimUtils.buildVimPlugin {
      pname = "vim-night-owl";
      version = "unstable-2021-05-16";
      src = pkgs.fetchFromGitHub {
        owner = "haishanh";
        repo = "night-owl.vim";
        rev = "783a41a27f7fe55ed91d1ec0f0351d06ae17fbc7";
        hash = "sha256-dI/Ag3FXiSy2ec7wC9wNJ15uAiYZEtu6gyyqU6BT98k=";
      };
    };
  steamConfigPython = pkgs: pkgs.python3.withPackages (ps: [ ps.vdf ]);
in
{
  # Home Manager is available on every NixOS evaluation through the delayed
  # integration module.  Each host explicitly selects whether its primary user
  # receives this managed profile.
  flake.modules.nixos.sam-home =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      host = config.my.host;
      enabled = host.home.enable;
      configurationName = lib.toLower host.name;
      isSteamDeck = host.roles.steamdeck;
      isNativePersonal = enabled && !host.roles.wsl && !isSteamDeck;
      username = if host.roles.wsl then "ssorensen" else "sam";
      homeDirectory = "/home/${username}";
      deployment = config.my.deployment;
      canDeployRemotely = deployment.canDeployRemotely && deployment.localFlakePath != null;
      sshHosts = {
        atlasuponraiden = {
          alias = "AtlasUponRaiden";
          HostName = "AtlasUponRaiden.${domain}";
          User = "sam";
          IdentityFile = "~/.ssh/atlasuponraiden_id_ed25519";
        };
        kamino = {
          alias = "Kamino";
          HostName = "Kamino.${domain}";
          User = "sam";
          IdentityFile = "~/.ssh/kamino_id_ed25519";
        };
        zaphodbeeblebrox = {
          alias = "ZaphodBeeblebrox";
          HostName = "ZaphodBeeblebrox.${domain}";
          User = "sam";
          IdentityFile = "~/.ssh/zaphod_id_ed25519";
        };
        naboo = {
          alias = "Naboo";
          HostName = "Naboo.${domain}";
          User = "sam";
          IdentityFile = "~/.ssh/naboo_id_ed25519";
        };
        nevarro = {
          alias = "Nevarro";
          HostName = "Nevarro.${domain}";
          User = "sam";
          IdentityFile = "~/.ssh/nevarro_id_ed25519";
        };
        nixpi = {
          alias = "NixPi";
          HostName = "NixPi.${domain}";
          User = "sam";
          IdentityFile = "~/.ssh/nixpi_id_ed25519";
        };
        emeraldecho = {
          alias = "EmeraldEcho";
          HostName = "EmeraldEcho.${domain}";
          User = "sam";
          IdentityFile = "~/.ssh/emeraldecho_id_ed25519";
        };
      };
      sshHostBlocks = lib.mapAttrs' (
        _: peer:
        lib.nameValuePair peer.alias (
          builtins.removeAttrs peer [ "alias" ]
          // {
            Port = 22;
            IdentitiesOnly = true;
          }
        )
      ) (lib.filterAttrs (_: peer: peer.alias != host.name) sshHosts);
      nixSshHostBlocks =
        lib.mapAttrs'
          (
            name: host:
            lib.nameValuePair "nix-${name}" {
              inherit (host) HostName;
              Port = 22;
              User = "nix-remote";
              IdentityFile = "~/.ssh/nix_${name}_id_ed25519";
              IdentitiesOnly = true;
            }
          )
          (
            lib.filterAttrs (
              name: _:
              builtins.elem name [
                "atlasuponraiden"
                "emeraldecho"
                "kamino"
                "naboo"
                "nevarro"
                "zaphodbeeblebrox"
              ]
            ) sshHosts
          );
      hasPodman = host.features.podman;
      inhibitSleep = deployment.sleepy;
      systemdInhibit = lib.getExe' pkgs.systemd "systemd-inhibit";
      nixProfile = "$HOME/.nix-profile/etc/profile.d/nix.sh";
      returnToGamingEntry = {
        name = "Return to Gaming Mode";
        exec = "qdbus org.kde.Shutdown /Shutdown logout";
        icon = "steam";
        terminal = false;
        categories = [ "System" ];
        comment = "Logout and return to Steam";
      };
      xrDriverRuntimeLibs = pkgs.lib.makeLibraryPath (
        with pkgs;
        [
          libevdev
          json_c
          curl
          openssl
          libusb1
          systemd
          wayland
        ]
      );
      steamConfigSeedScript = pkgs.writeText "steam-config-seed.py" ''
        import collections
        import pathlib
        import shutil
        import sys
        import vdf

        config_path = pathlib.Path.home() / ".local/share/Steam/config/config.vdf"
        config_path.parent.mkdir(parents=True, exist_ok=True)
        install_config = collections.OrderedDict()

        if config_path.exists():
            backup_path = config_path.with_suffix(config_path.suffix + ".pre-nix-backup")
            shutil.copy2(config_path, backup_path)
            try:
                with config_path.open("r", encoding="utf-8") as fp:
                    install_config = vdf.load(fp, mapper=collections.OrderedDict)
            except Exception as exc:
                print(f"Failed to parse {config_path}: {exc}", file=sys.stderr)
                raise SystemExit(0)

        root = install_config.setdefault("InstallConfigStore", collections.OrderedDict())
        steam = root.setdefault("Software", collections.OrderedDict()).setdefault("Valve", collections.OrderedDict()).setdefault("Steam", collections.OrderedDict())
        steam.setdefault("System", collections.OrderedDict()).update({
            "WifiPowerManagementEnabled": "1",
            "AllowBatteryLowPowerDownloads": "1",
        })
        steam.setdefault("ShaderCacheManager", collections.OrderedDict()).update({
            "EnableShaderBackgroundProcessing": "1",
        })
        display = root.setdefault("UI", collections.OrderedDict()).setdefault("display", collections.OrderedDict())
        display.setdefault("Current", collections.OrderedDict()).update({"ScaleFactor": "1.2"})
        display.setdefault('Internal: gamescope 7"', collections.OrderedDict()).update({"ScaleFactor": "1.2"})
        root.setdefault("SteamOS", collections.OrderedDict()).update({
            "ChargeLimitEnabled": "1",
            "ChargeLimit": "90",
        })

        with config_path.open("w", encoding="utf-8") as fp:
            vdf.dump(install_config, fp, pretty=True, escaped=True)
      '';
    in
    lib.mkIf enabled {
      # Steam Deck has no separate account module. WSL's host module owns its
      # ssorensen account, so do not redefine it here.
      users.groups.${username} = lib.mkIf isSteamDeck { };
      users.users.${username} = lib.mkIf isSteamDeck {
        isNormalUser = true;
        group = username;
        shell = pkgs.bash;
        extraGroups = [ ];
      };

      home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];

      home-manager.users.${username} = {
        imports = [
          inputs.nix-index-database.homeModules.nix-index
        ]
        ++ lib.optionals host.roles.wsl [ "${inputs.nix-work-secrets}/modules/sam-secrets-private.nix" ];
        home = {
          username = lib.mkForce username;
          homeDirectory = lib.mkForce homeDirectory;
          stateVersion = "26.11";
          packages =
            with pkgs;
            [
              cowsay
              fortune
              jq
              lolcat
              mediainfo
              nerd-fonts.caskaydia-cove
              comma
              (runCommandLocal "gitignore" { } ''
                install -Dm755 ${inputs.gitignore}/gitignore "$out/bin/gitignore"
              '')
            ]
            ++ lib.optionals (host.features.gui && !host.roles.wsl) [
              clementine
              discord
              ferdium
              plex-desktop
              signal-desktop
              vlc
            ];
          sessionVariables.XDG_CONFIG_HOME = lib.mkDefault "$HOME/.config";
        };
        programs = {
          home-manager.enable = true;
          gh = {
            enable = true;
            gitCredentialHelper.enable = true;
          };
          nix-index = {
            enable = true;
            enableBashIntegration = true;
            enableFishIntegration = true;
            enableZshIntegration = true;
          };
          git = {
            enable = true;
            settings = {
              user = lib.mkIf isNativePersonal {
                name = gitValue "git/name.txt";
                email = gitValue "git/email.txt";
                signingKey = gitValue "gpg-keys/signing-key-hash.txt";
              };
              alias = {
                s = "status";
                co = "checkout";
                ci = "commit -p -v";
                ai = "add -p -v";
                br = "branch";
                lg = "log --graph --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
                di = "diff --color-words";
              };
              branch.sort = "-committerdate";
              color = {
                ui = "auto";
                interactive = "auto";
                diff.whitespace = "red reverse";
              };
              commit = {
                verbose = true;
                gpgSign = true;
              };
              core = {
                editor = "vim";
                pager = "less -r";
                excludesFile = "$HOME/.gitignore_global";
                fsmonitor = true;
                untrackedCache = true;
                whitespace = "trailing-space,space-before-tab";
              };
              diff = {
                algorithm = "histogram";
                colorMoved = "plain";
                mnemonicPrefix = true;
                renames = true;
              };
              fetch = {
                prune = true;
                pruneTags = true;
                all = true;
              };
              help.autocorrect = "prompt";
              init.defaultBranch = "main";
              merge.conflictstyle = "zdiff3";
              pull.rebase = true;
              push = {
                default = "simple";
                autoSetupRemote = true;
                followTags = true;
              };
              rebase = {
                autoStash = true;
                autoSquash = true;
                updateRefs = true;
              };
              rerere = {
                enabled = true;
                autoupdate = true;
              };
              tag = {
                gpgSign = true;
                sort = "-version:refname";
              };
              gpg.program = "gpg";
            };
          };
          gpg = lib.mkIf isNativePersonal {
            enable = true;
            mutableKeys = true;
            mutableTrust = true;
            publicKeys = map (name: {
              source = "${inputs.nix-secrets}/gpg-keys/${name}";
              trust = "ultimate";
            }) gpgKeyFiles;
          };
          # Personal MCPs are an explicit profile choice. In particular, WSL
          # is VM-shaped but used for work, so form factor is not a useful
          # proxy for this policy.
          mcp = lib.mkIf host.features.personalMcp {
            enable = true;
            servers = {
              Arr = {
                command = "npx";
                args = [
                  "-y"
                  "mcp-arr-server"
                ];
                env = { };
              };
              Context7 = {
                url = "https://mcp.context7.com/mcp";
                headers.CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
              };
              GitHub = {
                url = "https://api.githubcopilot.com/mcp";
                headers.Authorization = "Bearer \${env:GITHUB_NIXOS_MCP_TOKEN}";
              };
              NixOS = {
                command = "nix";
                args = [
                  "run"
                  "github:utensils/mcp-nixos"
                  "--"
                ];
                startup_timeout_sec = 300;
              };
            };
          };
          vim = lib.mkIf (!host.roles.wsl) {
            enable = true;
            defaultEditor = true;
            plugins = [ pkgs.vimPlugins.vim-fish ] ++ lib.optionals isNativePersonal [ (vimNightOwl pkgs) ];
            extraConfig = ''
              set expandtab ignorecase number smartcase
              set shiftwidth=4 tabstop=4 softtabstop=4
              set backspace=indent,start,eol incsearch hlsearch autoindent
              set scrolloff=10 sidescrolloff=10
              imap jj <ESC>
              map 0 ^
              set smartindent smarttab cindent showmatch ruler
              syntax on
              set pastetoggle=<F4>
              nnoremap <F5> :set nonumber!<CR>
              set splitbelow splitright encoding=utf-8
              set list listchars=tab:»·,trail:·,extends:>,precedes:<,nbsp:+
              set cursorline cursorcolumn showcmd wildmenu
              set wildmode=list:longest,full
              set wildignore=*.o,*~,*.pyc,*.hi
              set matchtime=2 display+=lastline autoread laststatus=2
              autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
              filetype plugin indent on
              if has("termguicolors") | set termguicolors | endif
              ${lib.optionalString isNativePersonal "colorscheme night-owl"}
            '';
          };
          bash = {
            enable = true;
            enableCompletion = true;
            profileExtra = lib.optionalString isSteamDeck ''
              if [ -e "${nixProfile}" ]; then
                . "${nixProfile}"
              fi
            '';
            bashrcExtra = ''
              [[ $- != *i* ]] && return
              if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && $SHLVL == 1 || -n $TMUX ]]; then
                shopt -q login_shell && LOGIN_OPTION="--login" || LOGIN_OPTION=""
                exec fish $LOGIN_OPTION
              fi
            '';
          };
          fish = {
            enable = true;
            generateCompletions = true;
            plugins = lib.mkIf (!host.roles.wsl) [
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
            interactiveShellInit = lib.mkIf (!host.roles.wsl) ''
              ${lib.optionalString canDeployRemotely ''
                # Make the checkout path available to deployment helpers and
                # interactive scripts.
                set -gx DENDRITIC_FLAKE_PATH ${lib.escapeShellArg deployment.localFlakePath}
              ''}
              if command -sq gpg
                set -gx GPG_TTY (tty)
              end
            '';
            functions = {
              ls = "command ls -la --color=auto $argv";
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
            }
            // lib.optionalAttrs host.is.rpi {
              piStatus = ''
                echo "🥧 Pi System Status ("(hostname)"):"
                echo "Uptime: "(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
                echo "Load: "(cat /proc/loadavg | cut -d' ' -f1-3)
                echo "Memory: "(free -b | awk '/^Mem:/ {printf "%.1fGi/%.1fGi (%.0f%%)", $3/1024/1024/1024, $2/1024/1024/1024, ($3/$2)*100}')
                echo "Disk: "(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')

                set -l temp_found false
                for zone in /sys/class/thermal/thermal_zone*/temp
                  if test -r "$zone"
                    set -l temp_millidegrees (cat "$zone" 2>/dev/null)
                    if test -n "$temp_millidegrees"; and test "$temp_millidegrees" -gt 0
                      echo "Temperature: "(math "$temp_millidegrees / 1000")"°C"
                      set temp_found true
                      break
                    end
                  end
                end

                if test "$temp_found" = false; and command -sq vcgencmd
                  set -l temp (sudo vcgencmd measure_temp 2>/dev/null | cut -d= -f2)
                  if test -n "$temp"
                    echo "Temperature: $temp"
                    set temp_found true
                  end
                end

                if test "$temp_found" = false
                  echo "Temperature: N/A"
                end

                if systemctl list-unit-files blocky.service >/dev/null 2>&1
                  if systemctl is-active --quiet blocky
                    echo "Blocky: ✅ Running"
                  else
                    echo "Blocky: ❌ Not running"
                  end
                end

                if systemctl list-unit-files netbird-management.service >/dev/null 2>&1
                  if systemctl is-active --quiet netbird-management
                    echo "Netbird Management: ✅ Running"
                  else
                    echo "Netbird Management: ❌ Not running"
                  end
                end
              '';
              piLogs = ''
                set -l lines 50
                if test (count $argv) -gt 0
                  set lines $argv[1]
                end
                echo "📋 Recent system logs (last $lines lines):"
                sudo journalctl -n "$lines" --no-pager
              '';
            }
            // {
              inhibitSleep = ''
                echo "🔒 Inhibiting sleep for: $argv"
                echo -ne "\033]0;$argv\007"
                systemd-inhibit --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who="$USER" --why=nixos-rebuild --mode=block $argv
              '';
            }
            // lib.optionalAttrs canDeployRemotely {
              nhs = ''
                if ${if inhibitSleep then "true" else "false"}
                  ${systemdInhibit} --what=shutdown:sleep:idle --who=nhs --why="NixOS local switch" --mode=block nh os switch ${deployment.localFlakePath} -H ${configurationName} --keep-going $argv
                else
                  nh os switch ${deployment.localFlakePath} -H ${configurationName} --keep-going $argv
                end
              '';
              # Keep explicit function names available for scripts and
              # interactive use; nhs/nhsu remain the short forms.
              nhSwitch = "nhs $argv";
              updateFirefoxCustomAddons = "update-firefox-addons ${deployment.localFlakePath}";
              nhsu = ''
                pushd ${deployment.localFlakePath}
                or return $status
                if ${if inhibitSleep then "true" else "false"}
                  ${systemdInhibit} --what=shutdown:sleep:idle --who=nhsu --why="Nix flake update" --mode=block nix flake update
                else
                  nix flake update
                end
                set -l update_status $status

                if test $update_status -eq 0
                  set -l max_passes 10
                  for pass in (seq $max_passes)
                    set -l before_state (sha256sum flake.nix flake.lock 2>/dev/null | string collect)
                    if ${if inhibitSleep then "true" else "false"}
                      ${systemdInhibit} --what=shutdown:sleep:idle --who=nhsu --why="Regenerate flake metadata" --mode=block nix run .#write-flake
                    else
                      nix run .#write-flake
                    end
                    set update_status $status
                    if test $update_status -ne 0
                      break
                    end
                    set -l after_state (sha256sum flake.nix flake.lock 2>/dev/null | string collect)
                    if test "$before_state" = "$after_state"
                      break
                    end
                    if test $pass -eq $max_passes
                      echo "write-flake did not settle after $max_passes passes"
                      set update_status 1
                    end
                  end
                end
                popd
                test $update_status -eq 0
                or return $update_status
                nhs $argv
              '';
              nhSwitchUpgrade = "nhsu $argv";
              # These inventory-era helpers remain public command names.  The
              # data is now intentionally small and explicit: the broadcast
              # configuration has one standalone Home Manager output (the
              # SteamOS side of Emerald Echo) and explicit named targets.
              remoteDeployMethod = ''
                switch (string lower $argv[1])
                  case emeraldecho
                    echo build-then-switch
                  case naboo nevarro
                    echo secure
                  case '*'
                    echo switch
                end
              '';
              remoteHomeOutput = ''
                switch (string lower $argv[1])
                  case emeraldecho
                    echo emeraldecho-steamos
                end
              '';
              remoteHomeUser = ''
                switch (string lower $argv[1])
                  case atlasuponraiden emeraldecho kamino naboo nevarro zaphodbeeblebrox
                    echo sam
                end
              '';
              nhSwitchRemote = ''
                set target_host_lower (string lower $argv[1])
                inhibitSleep nh os switch ${deployment.localFlakePath} -H $target_host_lower --target-host "nix-$target_host_lower" --keep-going $argv[2..-1]
              '';
              nhSwitchUpgradeRemote = ''
                set target_host_lower (string lower $argv[1])
                inhibitSleep nh os switch ${deployment.localFlakePath} -H $target_host_lower --target-host "nix-$target_host_lower" --update --keep-going $argv[2..-1]
              '';
              nhBuildThenSwitchRemote = ''
                set target_host $argv[1]
                if test -z "$target_host"
                  echo "Usage: <command> <target_host> [additional_args...]"
                  return 1
                end
                set target_host_lower (string lower $target_host)
                set switch_target_host "nix-$target_host_lower"
                set ping_host "$target_host.${domain}"
                set ssh_ping_host (ssh -G $target_host 2>/dev/null | string match -r "^[Hh]ostname " | string replace -r "^[Hh]ostname " "")
                if test -n "$ssh_ping_host"
                  set ping_host $ssh_ping_host
                end
                echo "🔨 Building $target_host locally before waiting for it to come online..."
                inhibitSleep nh os build ${deployment.localFlakePath} -H $target_host_lower --keep-going $argv[2..-1]
                or return $status
                if command -sq notify-send
                  notify-send "Steam Deck build complete" "Turn on $target_host. Deployment will continue after it responds to ping."
                end
                echo "Build completed for $target_host."
                echo "Turn on $target_host, then press Enter to start waiting for network reachability."
                read
                echo "Waiting for $target_host at $ping_host to respond to ping..."
                while not ping -c 1 -W 1 $ping_host >/dev/null 2>&1
                  sleep 5
                end
                echo "$target_host is reachable. Starting remote switch..."
                inhibitSleep nh os switch ${deployment.localFlakePath} -H $target_host_lower --target-host $switch_target_host --keep-going $argv[2..-1]
              '';
              nhBuildThenSwitchUpgradeRemote = ''
                set target_host $argv[1]
                if test -z "$target_host"
                  echo "Usage: <command> <target_host> [additional_args...]"
                  return 1
                end
                set target_host_lower (string lower $target_host)
                set switch_target_host "nix-$target_host_lower"
                set ping_host "$target_host.${domain}"
                set ssh_ping_host (ssh -G $target_host 2>/dev/null | string match -r "^[Hh]ostname " | string replace -r "^[Hh]ostname " "")
                if test -n "$ssh_ping_host"
                  set ping_host $ssh_ping_host
                end
                echo "🔨 Building $target_host locally before waiting for it to come online..."
                inhibitSleep nh os build ${deployment.localFlakePath} -H $target_host_lower --update --keep-going $argv[2..-1]
                or return $status
                if command -sq notify-send
                  notify-send "Steam Deck build complete" "Turn on $target_host. Deployment will continue after it responds to ping."
                end
                echo "Build completed for $target_host."
                echo "Turn on $target_host, then press Enter to start waiting for network reachability."
                read
                echo "Waiting for $target_host at $ping_host to respond to ping..."
                while not ping -c 1 -W 1 $ping_host >/dev/null 2>&1
                  sleep 5
                end
                echo "$target_host is reachable. Starting remote switch..."
                inhibitSleep nh os switch ${deployment.localFlakePath} -H $target_host_lower --target-host $switch_target_host --update --keep-going $argv[2..-1]
              '';
              secureDeployConfig = ''
                switch (string lower $argv[1])
                  case naboo
                    printf '%s\n' '{"peerIp":"192.168.1.4","peerName":"Nevarro","peerServices":["blocky","coredns","dhcp-coredns-kea"],"probeDomains":["naboo.${domain}","nevarro.${domain}","atlasuponraiden.${domain}"],"targetServices":["blocky","coredns","dhcp-failover.timer"]}'
                  case nevarro
                    printf '%s\n' '{"peerIp":"192.168.1.3","peerName":"Naboo","peerServices":["blocky","coredns","dhcp-failover.timer"],"probeDomains":["naboo.${domain}","nevarro.${domain}","atlasuponraiden.${domain}"],"targetServices":["blocky","coredns","dhcp-coredns-kea"]}'
                  case '*'
                    return 1
                end
              '';
              secureDeployChecked = ''
                if test (remoteDeployMethod $argv[1]) = "build-then-switch"
                  echo "Use nhsur for Steam Deck deployment"
                  return 1
                end
                secure-deploy --upgrade $argv
              '';
              homeManagerSwitchRemote = ''
                set target_spec $argv[1]
                set target_host $target_spec
                if test -z "$target_spec"
                  echo "Usage: <command> <target_host|user@target_host> [build_args...]"
                  return 1
                end
                set remote_user ""
                if string match -q '*@*' $target_spec
                  set remote_user (string split -m1 '@' $target_spec)[1]
                  set target_host (string split -m1 '@' $target_spec)[2]
                end
                set home_output (remoteHomeOutput $target_host)
                if test -z "$home_output"
                  echo "No remote Home Manager output is defined for $target_host"
                  return 1
                end
                if test -z "$remote_user"
                  set remote_user (remoteHomeUser $target_host)
                end
                if test -z "$remote_user"
                  echo "No remote SSH user is defined for $target_host"
                  return 1
                end
                set configured_remote_user (remoteHomeUser $target_host)
                if test "$remote_user" = "$configured_remote_user"
                  set remote_target "$target_host"
                else
                  set remote_target "$remote_user@$target_host"
                end
                set remote_store_url "ssh://$remote_target?remote-program=/home/$remote_user/.nix-profile/bin/nix-store"
                set remote_method (remoteDeployMethod $target_host)
                set ping_host "$target_host.${domain}"
                set ssh_ping_host (ssh -G $target_host 2>/dev/null | string match -r "^[Hh]ostname " | string replace -r "^[Hh]ostname " "")
                if test -n "$ssh_ping_host"
                  set ping_host $ssh_ping_host
                end
                echo "🔨 Building $home_output locally..."
                inhibitSleep nix build ${deployment.localFlakePath}#$home_output $argv[2..-1]
                or return $status
                set store_path (nix path-info ${deployment.localFlakePath}#$home_output)
                or return $status
                if test "$remote_method" = "build-then-switch"
                  if command -sq notify-send
                    notify-send "Home Manager build complete" "Turn on $target_host. Activation will continue after it responds to ping."
                  end
                  echo "Build completed for $target_host."
                  echo "Turn on $target_host, then press Enter to start waiting for network reachability."
                  read
                  echo "Waiting for $target_host at $ping_host to respond to ping..."
                  while not ping -c 1 -W 1 $ping_host >/dev/null 2>&1
                    sleep 5
                  end
                end
                echo "📦 Copying $home_output to $remote_target..."
                inhibitSleep nix copy --to "$remote_store_url" ${deployment.localFlakePath}#$home_output
                or return $status
                echo "🚀 Activating Home Manager on $remote_target..."
                ssh $remote_target "HOME=/home/$remote_user PATH=/home/$remote_user/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/bin:/bin:\$PATH bash -lc '$store_path/activate'"
              '';
              cleanGenerations = ''
                nix-collect-garbage -d
                or return $status
                sudo nix-collect-garbage -d
                or return $status
                sudo nix store gc
                or return $status
                sudo nix store optimise
                or return $status
                sudo /run/current-system/bin/switch-to-configuration boot
              '';
              # The guarded RPi deployment path verifies its DNS peer before
              # taking a target-side lock and switching the configuration.
              secure-deploy = ''
                set -l upgrade false
                set -l tail false
                set -l target ""
                set -l additional_args
                for arg in $argv
                  switch $arg
                    case --upgrade
                      set upgrade true
                    case --tail
                      set tail true
                    case '*'
                      if test -z "$target"
                        set target $arg
                      else
                        set additional_args $additional_args $arg
                      end
                  end
                end
                if test -z "$target"
                  echo "Usage: secure-deploy [--upgrade] [--tail] <Naboo|Nevarro> [nh arguments...]"
                  return 2
                end
                set -l target_lower (string lower $target)
                set -l lock_host "nix-$target_lower"
                set -l target_ssh $lock_host
                if $tail
                  set target_ssh "$target_ssh-tail"
                end
                set -l config_json (secureDeployConfig $target)
                if test $status -ne 0 -o -z "$config_json"
                  echo "No secure deployment topology is defined for $target"
                  return 1
                end
                set -l peer_ip (printf '%s\n' "$config_json" | jq -r '.peerIp')
                set -l peer_name (printf '%s\n' "$config_json" | jq -r '.peerName')
                set -l probe_domains (printf '%s\n' "$config_json" | jq -r '.probeDomains[]')
                set -l peer_services (printf '%s\n' "$config_json" | jq -r '.peerServices[]')
                set -l target_services (printf '%s\n' "$config_json" | jq -r '.targetServices[]')
                set -l target_store "ssh://$target_ssh"
                set -l peer_ssh "nix-"(string lower $peer_name)
                function __secure_deploy_service_cmd
                  set checks
                  for service in $argv
                    set checks $checks "systemctl is-active --quiet $service"
                  end
                  string join " && " $checks
                end
                echo "🔍 Checking health of $peer_name ($peer_ip) before deploying to $target..."
                if not timeout 10 dig @$peer_ip -p 53 google.com +short >/dev/null 2>&1
                  echo "❌ ERROR: $peer_name DNS on :53 is not responding!"
                  functions -e __secure_deploy_service_cmd
                  return 1
                end
                for domain in $probe_domains
                  if not timeout 10 dig @$peer_ip -p 53 $domain +short >/dev/null 2>&1
                    echo "❌ ERROR: $peer_name cannot resolve $domain through Blocky/CoreDNS!"
                    functions -e __secure_deploy_service_cmd
                    return 1
                  end
                end
                set -l peer_service_cmd (__secure_deploy_service_cmd $peer_services)
                if test -n "$peer_service_cmd"
                  if not ssh $peer_ssh "$peer_service_cmd" 2>/dev/null
                    echo "❌ ERROR: $peer_name is not healthy for safe deployment!"
                    echo "   Expected active services: "(string join ", " $peer_services)
                    functions -e __secure_deploy_service_cmd
                    return 1
                  end
                end
                if ssh $peer_ssh 'test -f /tmp/.deploy-lock' 2>/dev/null
                  echo "❌ ERROR: Deployment already in progress on $peer_name!"
                  functions -e __secure_deploy_service_cmd
                  return 1
                end
                if not ssh $lock_host 'test ! -e /tmp/.deploy-lock && printf "%s\\n" deploy > /tmp/.deploy-lock'
                  echo "Refusing deployment: target deployment lock is present or inaccessible"
                  return 1
                end
                function __secure_deploy_cleanup --inherit-variable lock_host
                  ssh $lock_host 'rm -f /tmp/.deploy-lock' >/dev/null 2>&1
                end
                function __secure_deploy_cleanup_signal --on-signal INT --on-signal TERM --inherit-variable lock_host
                  __secure_deploy_cleanup
                end
                function __secure_deploy_cleanup_exit --on-event fish_exit --inherit-variable lock_host
                  __secure_deploy_cleanup
                end
                if $upgrade
                  if ${if inhibitSleep then "true" else "false"}
                    ${systemdInhibit} --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who=secure-deploy --why="NixOS remote deployment" --mode=block nh os switch ${deployment.localFlakePath} -H $target_lower --target-host $target_store --update --keep-going $additional_args
                  else
                    nh os switch ${deployment.localFlakePath} -H $target_lower --target-host $target_store --update --keep-going $additional_args
                  end
                else
                  if ${if inhibitSleep then "true" else "false"}
                    ${systemdInhibit} --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who=secure-deploy --why="NixOS remote deployment" --mode=block nh os switch ${deployment.localFlakePath} -H $target_lower --target-host $target_store --keep-going $additional_args
                  else
                    nh os switch ${deployment.localFlakePath} -H $target_lower --target-host $target_store --keep-going $additional_args
                  end
                end
                set -l result $status
                if test $result -eq 0
                  echo "🔍 Running post-deployment validation on $target..."
                  sleep 10
                  set -l post_deploy_dns_output (ssh $target_ssh 'timeout 10 dig @127.0.0.1 -p 53 google.com +short' 2>/dev/null)
                  if test $status -ne 0
                    if test -n "$post_deploy_dns_output"
                      echo $post_deploy_dns_output
                    end
                    echo "❌ CRITICAL: Post-deployment DNS check failed on $target!"
                    set result 1
                  end
                  if test $result -eq 0
                    set -l target_service_cmd (__secure_deploy_service_cmd $target_services)
                    if test -n "$target_service_cmd"
                      if not ssh $target_ssh "$target_service_cmd" 2>/dev/null
                        echo "❌ CRITICAL: Post-deployment service health check failed on $target!"
                        echo "   Expected active services: "(string join ", " $target_services)
                        set result 1
                      end
                    end
                  end
                  if test $result -eq 0
                    for domain in $probe_domains
                      if not ssh $target_ssh "timeout 10 dig @127.0.0.1 -p 53 $domain +short" >/dev/null 2>&1
                        echo "❌ CRITICAL: Post-deployment local DNS integration check failed for $domain!"
                        set result 1
                        break
                      end
                    end
                  end
                  if test $result -eq 0
                    echo "✅ Deployment to $target completed successfully"
                  end
                end
                __secure_deploy_cleanup
                functions -e __secure_deploy_cleanup __secure_deploy_cleanup_signal __secure_deploy_cleanup_exit __secure_deploy_service_cmd
                return $result
              '';
              remote-deploy = ''
                set -l upgrade false
                if test "$argv[1]" = --upgrade
                  set upgrade true
                  set -e argv[1]
                end
                if test (count $argv) -lt 1
                  echo "Usage: remote-deploy [--upgrade] <configuration> [nh arguments...]"
                  return 2
                end
                if string match -q '*@*' $argv[1]
                  if $upgrade
                    echo "Home Manager remote activation uses the current flake state; no separate --update mode is applied."
                  end
                  homeManagerSwitchRemote $argv
                  return $status
                end
                switch (remoteDeployMethod $argv[1])
                  case secure
                    if $upgrade
                      secure-deploy --upgrade $argv
                    else
                      secure-deploy $argv
                    end
                  case build-then-switch
                    if $upgrade
                      nhBuildThenSwitchUpgradeRemote $argv
                    else
                      nhBuildThenSwitchRemote $argv
                    end
                  case '*'
                    if $upgrade
                      nhSwitchUpgradeRemote $argv
                    else
                      nhSwitchRemote $argv
                    end
                end
              '';
              nhsr = "remote-deploy $argv";
              nhsur = "remote-deploy --upgrade $argv";
              nhsur_unsafe = ''
                if test (count $argv) -lt 1
                  echo "Usage: nhsur_unsafe <configuration> [nh arguments...]"
                  return 2
                end
                set -l target $argv[1]
                set -l target_lower (string lower $target)
                if ${if inhibitSleep then "true" else "false"}
                  ${systemdInhibit} --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who=nhsur_unsafe --why="NixOS remote deployment" --mode=block nh os switch ${deployment.localFlakePath} -H $target_lower --target-host "nix-$target_lower" --update --keep-going $argv[2..-1]
                else
                  nh os switch ${deployment.localFlakePath} -H $target_lower --target-host "nix-$target_lower" --update --keep-going $argv[2..-1]
                end
              '';
            }
            // lib.optionalAttrs hasPodman {
              podmanSystem = "sudo podman $argv";
              pds = "podmanSystem";
              podmanSystemPs = "sudo podman ps --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'";
              podmanSystemPsAll = "sudo podman ps -a --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'";
              podmanUserPs = "podman ps --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'";
              podmanUserPsAll = "podman ps -a --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'";
              pps = "podmanSystemPs";
              ppsa = "podmanSystemPsAll";
              ppu = "podmanUserPs";
              ppua = "podmanUserPsAll";
              dps = "podmanSystemPsAll";
              podmanUnitName = ''
                set name $argv[1]
                if test -z "$name"
                  return 1
                end
                if string match -q 'podman-*.service' -- "$name"
                  echo "$name"
                else if string match -q '*.service' -- "$name"
                  echo "podman-"(string replace -r '\\.service$' "" -- "$name")".service"
                else
                  echo "podman-$name.service"
                end
              '';
              podmanContainerName = ''
                set unit (podmanUnitName $argv[1])
                or return 1
                string replace -r '^podman-(.*)\\.service$' '$1' -- "$unit"
              '';
              podmanServices = "systemctl list-units --type=service --all 'podman-*.service'";
              pcs = "podmanServices";
              podmanServiceStatus = ''
                for name in $argv
                  set unit (podmanUnitName $name)
                  or return 1
                  sudo systemctl status $unit
                end
              '';
              podmanServiceLogs = ''
                for name in $argv
                  set unit (podmanUnitName $name)
                  or return 1
                  sudo journalctl -u $unit -f
                end
              '';
              podmanServicePull = ''
                if test (count $argv) -eq 0
                  echo "Usage: podmanServicePull <container|service> [...]"
                  return 1
                end
                for name in $argv
                  set container (podmanContainerName $name)
                  or return 1
                  set image (sudo podman inspect --format '{{.ImageName}}' $container 2>/dev/null)
                  if test -z "$image"
                    echo "No existing rootful container found for $name" >&2
                    return 1
                  end
                  echo "Pulling $image"
                  sudo podman pull $image
                  or return $status
                end
              '';
              podmanServiceUp = ''
                if test (count $argv) -eq 0
                  echo "Usage: podmanServiceUp <container|service> [...]"
                  return 1
                end
                for name in $argv
                  set unit (podmanUnitName $name)
                  or return 1
                  if sudo systemctl is-active --quiet $unit
                    sudo systemctl restart $unit
                  else
                    sudo systemctl start $unit
                  end
                  or return $status
                end
              '';
              pcss = "podmanServiceStatus";
              pcsl = "podmanServiceLogs";
              pcp = "podmanServicePull";
              pcu = "podmanServiceUp";
              dcp = "podmanServicePull";
              dcu = "podmanServiceUp";
            };
          };
          atuin = lib.mkIf isNativePersonal {
            enable = true;
            enableBashIntegration = true;
            enableFishIntegration = true;
            daemon.enable = true;
            forceOverwriteSettings = true;
            settings = {
              sync_address = "https://${domain}/atuin/";
              sync_frequency = "0";
              search_mode = "daemon-fuzzy";
              search_mode_shell_up_key_binding = "daemon-fuzzy";
              filter_mode_shell_up_key_binding = "session-preload";
              workspaces = true;
              style = "auto";
              command_chaining = true;
              enter_accept = true;
              keymap_mode = "vim-normal";
              sync.records = true;
              theme.name = "marine";
            };
          };
          ssh = lib.mkIf isNativePersonal {
            enable = true;
            enableDefaultConfig = false;
            settings = {
              "*" = {
                AddKeysToAgent = "yes";
                ForwardAgent = true;
                Compression = true;
                ServerAliveInterval = 0;
                ServerAliveCountMax = 3;
                HashKnownHosts = false;
                UserKnownHostsFile = "~/.ssh/known_hosts";
              };
              GitHub = {
                HostName = "github.com";
                User = "git";
                IdentityFile = "~/.ssh/github_id_ed25519";
                IdentitiesOnly = true;
              };
            }
            // sshHostBlocks
            // lib.optionalAttrs canDeployRemotely nixSshHostBlocks;
          };
          starship = {
            enable = true;
            enableBashIntegration = false;
            enableFishIntegration = true;
            settings = {
              add_newline = false;
              package.disabled = true;
              format = "[┬─](bold purple)[\\[](dimmed blue)$username[@](bold bright-white)$hostname[:](bold bright-white)$directory[\\]](dimmed blue)[─](bold purple)$time[─](bold purple)$git_branch$git_commit$git_state$git_status$kubernetes$dotnet$golang$nodejs$python$rust$terraform$memory_usage$jobs $battery$line_break$cmd_duration[╰─⮞ ](bold purple)$character";
              username = {
                format = "[$user]($style)";
                show_always = true;
                style_user = "bold cyan";
              };
              hostname = {
                format = "[$ssh_symbol$hostname]($style)";
                ssh_symbol = "🌐";
                ssh_only = false;
                style = "bold blue";
              };
              battery = {
                charging_symbol = "󰂄";
                discharging_symbol = "💦";
                empty_symbol = "󰂎";
                full_symbol = "󰁹";
                unknown_symbol = "󰂑";
                format = "[$symbol$percentage]($style)";
                display = [
                  {
                    threshold = 100;
                    charging_symbol = "󰢞 ";
                    discharging_symbol = "󰁹";
                    style = "bold green";
                  }
                  {
                    threshold = 70;
                    charging_symbol = "󰢞 ";
                    discharging_symbol = "󰂀";
                    style = "bold orange";
                  }
                  {
                    threshold = 50;
                    charging_symbol = "󰢝 ";
                    discharging_symbol = "󰁾";
                    style = "bold yellow";
                  }
                  {
                    threshold = 25;
                    charging_symbol = "󰂆 ";
                    discharging_symbol = "󰁻";
                    style = "bold red";
                  }
                ];
              };
              directory = {
                fish_style_pwd_dir_length = 1;
                format = "[$path/]($style)[$read_only]($read_only_style)";
                style = "bold green";
              };
              time = {
                disabled = false;
                format = "[\\[](dimmed blue)[$time]($style)[\\]](dimmed blue)";
                style = "bright-blue";
              };
              git_branch = {
                format = "[\\[](dimmed blue)[$symbol$branch]($style)[\\]](dimmed blue)";
                symbol = " ";
              };
              dotnet = {
                symbol = ".NET";
                disabled = false;
              };
              memory_usage = {
                disabled = false;
                format = "[\\[$symbol{$ram}(|{$swap})\\]]($style)";
                symbol = "🐏";
                threshold = -1;
              };
              cmd_duration.format = "[├](bold purple) command took [$duration]($style)\n";
              nix_shell.disabled = false;
              character = {
                success_symbol = "[\\$](bold green)";
                error_symbol = "[✗](bold red)";
              };
            };
          };
          tmux = {
            enable = true;
            clock24 = true;
            extraConfig = ''
              setw -g mode-keys vi
              set -g default-terminal "xterm-256color"
              setw -g monitor-activity on
              set -g visual-activity on
              set mouse on
              is_vim='echo "#{pane_current_command}" | grep -iqE "(^|/)g?(view|n?vim?)(diff)?$"'
              bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
              bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
              bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
              bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"
              bind -n C-\\ if-shell "$is_vim" "send-keys C-\\" "select-pane -l"
              bind-key r refresh-client \; display-message "Refreshed!"
              bind Escape copy-mode
              unbind p
              bind p paste-buffer
              bind -T copy-mode-vi 'v' send-keys -X begin-selection
              bind -T copy-mode-vi 'y' send-keys -X copy-selection
              bind -T copy-mode-vi 'Space' send-keys -X halfpage-down
              bind -T copy-mode-vi 'Bspace' send-keys -X halfpage-up
              bind C-c run "tmux save-buffer - | xclip -i -sel clipboard"
              bind C-v run "tmux set-buffer \"$(xclip -o -sel clipboard)\"; tmux paste-buffer"
              bind | split-window -h
              bind - split-window -v
              unbind '"'
              unbind %
              bind -r H resize-pane -L 5
              bind -r J resize-pane -D 5
              bind -r K resize-pane -U 5
              bind -r L resize-pane -R 5
            '';
          };
        };
        services.gpg-agent = lib.mkIf isNativePersonal {
          enable = true;
          defaultCacheTtl = 1800;
          maxCacheTtl = 7200;
          enableFishIntegration = true;
          enableSshSupport = true;
          pinentry.package = pkgs.pinentry-qt;
          extraConfig = ''
            allow-loopback-pinentry
            default-cache-ttl-ssh 1800
            max-cache-ttl-ssh 7200
          '';
        };

        # Clear locks left behind by an interrupted keyboxd/GPG process before
        # the agent starts. This prevents persistent
        # "database_open waiting for lock" failures after interrupted runs.
        systemd.user.services.gpg-cleanup-stale-locks = lib.mkIf isNativePersonal {
          Unit = {
            Description = "Remove stale GPG keybox lock files";
            Before = [ "gpg-agent.service" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.findutils}/bin/find %h/.gnupg -name .#lk* -delete 2>/dev/null; rm -f %h/.gnupg/public-keys.d/pubring.db.lock'";
          };
          Install.WantedBy = [ "gpg-agent.service" ];
        };

        sops = lib.mkIf isSteamDeck {
          age.sshKeyPaths = [ "${homeDirectory}/.ssh/sops_ed25519" ];
          defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
        };

        xdg = lib.mkIf isSteamDeck {
          enable = true;
          desktopEntries.return-to-gaming = returnToGamingEntry;
        };

        home.file = lib.mkMerge [
          (lib.mkIf isSteamDeck {
            ".config/reshade/Shaders/.keep".text = "";
            ".config/reshade/Textures/.keep".text = "";
            ".local/share/gamescope/reshade/Shaders/.keep".text = "";
            ".local/share/gamescope/reshade/Textures/.keep".text = "";
            ".local/share/breezy_vulkan/.keep".text = "";
          })
        ];
        # Avoid generating per-user man-cache/manpath state on WSL.
        programs.man.generateCaches = false;
        programs.command-not-found.enable = false;

        systemd.user.services.xr-driver = lib.mkIf isSteamDeck {
          Unit = {
            Description = "XR user-space driver";
            After = [ "default.target" ];
            ConditionPathExists = "%h/.local/bin/xrDriver";
          };
          Service = {
            Type = "simple";
            Environment = [ "LD_LIBRARY_PATH=%h/.local/share/xr_driver/lib:${xrDriverRuntimeLibs}" ];
            ExecStart = "%h/.local/bin/xrDriver";
            Restart = "always";
          };
          Install.WantedBy = [ "default.target" ];
        };

        home.activation = lib.mkIf isSteamDeck {
          xrDriverCleanup = inputs.home-manager.lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
            rm -f "$HOME/.config/systemd/user/default.target.wants/xr-driver.service"
          '';
          seedSteamConfig = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD ${steamConfigPython pkgs}/bin/python3 ${steamConfigSeedScript}
          '';
        };
      };
    };
}
