{ inputs, ... }:
{
  # Windows owns the VS Code executable and extensions for this WSL profile.
  # Home Manager owns a small Linux-side User tree and mirrors it into the
  # writable Windows profile after activation.
  flake.modules.nixos.wsl-vscode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      managedPaths = [
        "settings.json"
        "keybindings.json"
        "mcp.json"
        "snippets"
        "profiles"
      ];
      managedPathsFile = pkgs.writeText "vscode-managed-paths.txt" (
        lib.concatStringsSep "\n" managedPaths + "\n"
      );
      # The Windows editor owns its extension directory. Keep the WSL
      # default/Higi inventory as data for on-demand installation without an
      # immutable Linux extension tree.
      defaultExtensionIds = [
        "docker.docker"
        "esbenp.prettier-vscode"
        "evondev.indent-rainbow-palettes"
        "github.vscode-github-actions"
        "humao.rest-client"
        "jeff-hykin.better-nix-syntax"
        "LiemLB.nix-flakes"
        "ms-azuretools.vscode-containers"
        "ms-vscode.remote-explorer"
        "ms-vscode-remote.remote-containers"
        "ms-vscode-remote.remote-ssh"
        "ms-vscode-remote.remote-ssh-edit"
        "ms-vscode-remote.remote-wsl"
        "oderwat.indent-rainbow"
        "redhat.vscode-yaml"
        "rimuruchan.vscode-fix-checksums-next"
        "sabrsorensen.party-owl-84"
        "sabrsorensen.synthwave-blues"
        "tomoki1207.pdf"
        "vscodevim.vim"
      ];
      pythonExtensionIds = [
        "ms-python.debugpy"
        "ms-python.python"
        "ms-python.vscode-pylance"
      ];
      higiExtensionIds = [
        "openai.chatgpt"
        "snyk-security.snyk-vulnerability-scanner"
        "pulumi.pulumi-vscode-tools"
        "ms-mssql.mssql"
        "ms-ossdata.vscode-pgsql"
      ];
      fishExtensionIds = [ "bmalehorn.vscode-fish" ];
      nixExtensionIds = [ "signageos.signageos-vscode-sops" ];
      extensionIds = lib.unique (
        defaultExtensionIds ++ pythonExtensionIds ++ higiExtensionIds ++ fishExtensionIds ++ nixExtensionIds
      );
      extensionIdsFile = pkgs.writeText "vscode-extension-ids.txt" (
        lib.concatStringsSep "\n" extensionIds + "\n"
      );
      # Resolve the extension closure from the Marketplace so profile data is
      # reproducible, even though Windows owns the live extension directory.
      vscodePackage =
        inputs.partyowl84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscode-partyowl84;
      mkExtensions =
        ids: pkgs.nix4vscode.forVscodeVersion (vscodePackage.vscodeVersion or vscodePackage.version) ids;
      # Windows owns the extension directory, while this configuration manages
      # its User/profile tree independently of the delivery mechanism.
      defaultSettings = {
        "[dockercompose]" = {
          "editor.autoIndent" = "advanced";
          "editor.defaultFormatter" = "redhat.vscode-yaml";
          "editor.insertSpaces" = true;
          "editor.quickSuggestions" = {
            comments = false;
            other = true;
            strings = true;
          };
          "editor.tabSize" = 2;
        };
        "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";
        "[json]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[jsonc]"."editor.defaultFormatter" = "vscode.json-language-features";
        "[nix]" = {
          "editor.tabSize" = 2;
          "editor.indentSize" = "tabSize";
        };
        "accessibility.signals.terminalBell"."sound" = "on";
        "chat.disableAIFeatures" = true;
        "debug.toolBarLocation" = "commandCenter";
        "diffEditor.ignoreTrimWhitespace" = false;
        "docker.extension.enableComposeLanguageServer" = true;
        "editor.acceptSuggestionOnCommitCharacter" = false;
        "editor.acceptSuggestionOnEnter" = "smart";
        "editor.bracketPairColorization.enabled" = true;
        "editor.cursorSurroundingLines" = 10;
        "editor.fontFamily" = "CaskaydiaCove Nerd Font Mono";
        "editor.fontLigatures" = true;
        "editor.formatOnSave" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.guides.bracketPairsHorizontal" = true;
        "editor.parameterHints.cycle" = true;
        "editor.quickSuggestions" = {
          other = "inline";
          comments = false;
          strings = false;
        };
        "editor.renderControlCharacters" = true;
        "editor.renderWhitespace" = "boundary";
        "editor.suggest.localityBonus" = true;
        "editor.suggest.shareSuggestSelections" = true;
        "editor.tabCompletion" = "on";
        "editor.tabSize" = 2;
        "explorer.confirmDelete" = false;
        "explorer.openEditors.visible" = 10;
        "extensions.closeExtensionDetailsOnViewChange" = true;
        "files.exclude" = {
          "**/.vs" = true;
          "**/TestResults" = true;
          "**/bin" = true;
          "**/obj" = true;
        };
        "files.trimFinalNewlines" = true;
        "files.trimTrailingWhitespace" = true;
        "git.autofetch" = true;
        "git.blame.editorDecoration.enabled" = true;
        "git.confirmSync" = false;
        "git.enableCommitSigning" = true;
        "git.fetchOnPull" = true;
        "python.analysis.autoImportCompletions" = true;
        "python.analysis.autoSearchPaths" = true;
        "python.analysis.completeFunctionParens" = true;
        "python.analysis.diagnosticSeverityOverrides" = {
          "reportMissingParameterType" = "warning";
          "reportUnknownArgumentType" = "warning";
          "reportUnknownMemberType" = "warning";
          "reportUnknownParameterType" = "warning";
          "reportUnknownVariableType" = "warning";
        };
        "python.analysis.indexing" = true;
        "python.analysis.typeCheckingMode" = "strict";
        "python.analysis.useLibraryCodeForTypes" = true;
        "python.languageServer" = "Pylance";
        "redhat.telemetry.enabled" = false;
        "remote.env"."NODE_EXTRA_CA_CERTS" = "/etc/ssl/certs/ca-bundle.crt";
        "remote.extensionKind"."oderwat.indent-rainbow" = [ "ui" ];
        "search.showLineNumbers" = true;
        "search.smartCase" = true;
        "telemetry.telemetryLevel" = "off";
        "terminal.integrated.copyOnSelection" = true;
        "terminal.integrated.cursorBlinking" = true;
        "terminal.integrated.defaultProfile.linux" = "fish";
        "terminal.integrated.enableVisualBell" = true;
        "terminal.integrated.fontFamily" = "CaskaydiaCove Nerd Font Mono";
        "terminal.integrated.fontLigatures.enabled" = true;
        "vim.autoindent" = true;
        "vim.foldfix" = true;
        "vim.handleKeys" = {
          "<C-a>" = false;
          "<C-b>" = false;
          "<C-c>" = false;
          "<C-e>" = false;
          "<C-f>" = false;
          "<C-j>" = false;
          "<C-k>" = false;
          "<C-p>" = false;
          "<C-v>" = true;
        };
        "vim.highlightedyank.enable" = true;
        "vim.hlsearch" = true;
        "vim.ignorecase" = true;
        "vim.incsearch" = true;
        "vim.smartcase" = true;
        "vim.sneak" = true;
        "vim.surround" = true;
        "vim.useCtrlKeys" = true;
        "vim.useSystemClipboard" = false;
        "window.commandCenter" = true;
        "window.newWindowDimensions" = "maximized";
        "window.newWindowProfile" = "Default";
        "window.restoreWindows" = "none";
        "workbench.editor.highlightModifiedTabs" = true;
        "workbench.editor.revealIfOpen" = true;
        "workbench.colorTheme" = "Party Owl '84";
        "workbench.preferredDarkColorTheme" = "Party Owl '84";
        "partyowl84.brightness" = 1;
        "partyowl84.disableGlow" = false;
        "editor.tokenColorCustomizations" = {
          "[Party Owl '84]" = {
            "textMateRules" = [
              {
                scope = [
                  "entity.other.attribute-name.nix"
                  "meta.attribute-key.nix"
                  "variable.other.object.nix"
                  "variable.other.object.parameter.nix"
                  "variable.other.object.property.nix"
                  "variable.parameter.function.nix"
                  "variable.parameter.nix"
                ];
                settings = {
                  foreground = "#C5E478";
                  fontStyle = "italic";
                };
              }
              {
                scope = [
                  "variable.interpolation"
                  "variable.other.normal.shell.nix"
                ];
                settings.foreground = "#ec5f67";
              }
              {
                scope = [
                  "variable.language.special"
                  "variable.language.special.shell.nix"
                  "variable.parameter.positional.shell.nix"
                ];
                settings.foreground = "#8EACE3";
              }
            ];
          };
        };
      };
      windowsTerminalSettings = {
        "terminal.integrated.defaultProfile.windows" = "NixOS (WSL)";
        "terminal.integrated.profiles.windows" = {
          "PowerShell" = {
            source = "PowerShell";
            icon = "terminal-powershell";
          };
          "Command Prompt" = {
            path = [
              "\${env =windir}\\Sysnative\\cmd.exe"
              "\${env =windir}\\System32\\cmd.exe"
            ];
            args = [ ];
            icon = "terminal-cmd";
          };
          "NixOS (WSL)" = {
            path = "C =\\windows\\System32\\wsl.exe";
            args = [
              "-d"
              "NixOS"
            ];
          };
        };
      };
      defaultProfileSettings =
        defaultSettings
        // windowsTerminalSettings
        // {
          "extensions.supportUntrustedWorkspaces" = {
            "sabrsorensen.party-owl-84".supported = true;
            "vscodevim.vim".supported = true;
          };
          "remote.SSH.experimental.chat" = false;
          "remote.SSH.remotePlatform" = {
            AtlasUponRaiden = "linux";
            EmeraldEcho = "linux";
            Kamino = "linux";
            Naboo = "linux";
            Nevarro = "linux";
            ZaphodBeeblebrox = "linux";
          };
          "remote.SSH.showLoginTerminal" = false;
          "remote.SSH.useLocalServer" = true;
          "settingsSync.keybindingsPerPlatform" = false;
          "settingsSync.ignoredSettings" = [ "*" ];
          "vim.insertModeKeyBindings" = [
            {
              before = [
                "j"
                "j"
              ];
              after = [ "<Esc>" ];
            }
          ];
          "vim.normalModeKeyBindings" = [
            {
              before = [ "0" ];
              after = [ "^" ];
            }
          ];
          "vim.visualModeKeyBindingsNonRecursive" = [
            {
              before = [ ">" ];
              commands = [ "editor.action.indentLines" ];
            }
            {
              before = [ "<" ];
              commands = [ "editor.action.outdentLines" ];
            }
          ];
        };
      higiSettings = defaultSettings // {
        "chatgpt.runCodexInWindowsSubsystemForLinux" = true;
        "extensions.verifySignature" = false;
        "snyk.advanced.cliPath" = "C:\\Users\\ssorensen\\AppData\\Local\\snyk\\vscode-cli\\snyk-win.exe";
        "snyk.securityAtInception.autoConfigureSnykMcpServer" = true;
        "snyk.securityAtInception.executionFrequency" = "On Code Generation";
      };
      higiMcp = {
        servers = {
          Arr = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "mcp-arr-server"
            ];
            enabled = true;
            env = { };
          };
          Context7 = {
            type = "http";
            url = "https://mcp.context7.com/mcp";
            enabled = true;
            headers.CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
          };
          GitHub = {
            type = "http";
            url = "https://api.githubcopilot.com/mcp";
            enabled = true;
            headers.Authorization = "Bearer \${env:GITHUB_NIXOS_MCP_TOKEN}";
          };
          NixOS = {
            type = "stdio";
            command = "nix";
            args = [
              "run"
              "github:utensils/mcp-nixos"
              "--"
            ];
            enabled = true;
            startup_timeout_sec = 300;
          };
        };
      };
      syncScript = pkgs.writeShellApplication {
        name = "editor-sync-windows";
        runtimeInputs = with pkgs; [
          coreutils
          findutils
          gnused
        ];
        text = ''
          set -eu

          install_extensions=0
          if [ "''${1:-}" = "--install-extensions" ]; then
            install_extensions=1
            shift
          fi

          if [ "$#" -ne 0 ]; then
            echo "Usage: editor-sync-windows [--install-extensions]" >&2
            exit 1
          fi

          if ! command -v cmd.exe >/dev/null 2>&1 || ! command -v wslpath >/dev/null 2>&1; then
            echo "Windows interop is unavailable; skipping VS Code profile sync." >&2
            exit 0
          fi

          appdata_win="$(cmd.exe /d /c echo %APPDATA% | tr -d '\r')"
          if [ -z "$appdata_win" ]; then
            echo "Unable to resolve %APPDATA%; skipping VS Code profile sync." >&2
            exit 0
          fi

          source_root="$HOME/.config/Code/User"
          export_root="$HOME/.local/state/vscode-sync/Code/User"
          target_root="$(wslpath -u "$appdata_win/Code/User")"
          if [ -z "$target_root" ]; then
            echo "Unable to resolve the Windows Code User directory; skipping VS Code profile sync." >&2
            exit 0
          fi

          sync_managed_path() {
            src_root="$1"
            dst_root="$2"
            rel_path="$3"
            dst_path="''${dst_root:?}/''${rel_path:?}"

            rm -rf -- "$dst_path"
            if [ -e "$src_root/$rel_path" ]; then
              mkdir -p "$dst_root/$(dirname "$rel_path")"
              cp -RL "$src_root/$rel_path" "$dst_root/$rel_path"
            fi
          }

          sync_tree() {
            src_root="$1"
            dst_root="$2"

            mkdir -p "$dst_root"
            while IFS= read -r rel_path; do
              if [ -n "$rel_path" ]; then
                sync_managed_path "$src_root" "$dst_root" "$rel_path"
              fi
            done < ${managedPathsFile}
          }

          mkdir -p "$export_root"
          cp ${extensionIdsFile} "$HOME/.local/state/vscode-sync/extensions.txt"
          sync_tree "$source_root" "$export_root"
          sync_tree "$export_root" "$target_root"

          if [ "$install_extensions" -eq 1 ]; then
            if ! command -v where.exe >/dev/null 2>&1 || ! where.exe code >/dev/null 2>&1; then
              echo "Windows Code CLI is unavailable; skipping extension installation." >&2
              exit 0
            fi
            while IFS= read -r extension_id; do
              [ -n "$extension_id" ] || continue
              cmd.exe /d /c code --install-extension "$extension_id" --force >/dev/null
            done < ${extensionIdsFile}
          fi
        '';
      };
    in
    lib.mkIf (config.my.host.platform == "wsl" && config.my.host.home.enable) {
      nixpkgs.overlays = [ inputs.nix4vscode.overlays.forVscode ];
      home-manager.users.ssorensen = {
        # WSL is a work profile, so configure the shared and Higi work MCPs
        # instead of the personal Arr client.
        programs.mcp = {
          enable = true;
          servers = {
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
              env = {
                SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
                REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
                CURL_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
                NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
              };
            };
            Azure = {
              command = "uvx";
              args = [
                "--from"
                "msmcp-azure"
                "azmcp"
                "server"
                "start"
              ];
              env.AZURE_TOKEN_CREDENTIALS = "AzureCliCredential";
              startup_timeout_sec = 300;
            };
            AZDORemote.url = "https://mcp.dev.azure.com/higicore";
            Postman = {
              command = "npx";
              args = [
                "@postman/postman-mcp-server"
                "--full"
                "--region"
                "us"
              ];
              env.POSTMAN_API_KEY = "\${env:POSTMAN_NIXOS_MCP_TOKEN}";
            };
            Pulumi = {
              url = "https://mcp.ai.pulumi.com/mcp";
              headers.Authorization = "Bearer \${env:PULUMI_NIXOS_MCP_TOKEN}";
            };
            Snyk = {
              command = "npx";
              args = [
                "-y"
                "snyk@latest"
                "mcp"
                "-t"
                "stdio"
              ];
              env.SNYK_TOKEN = "\${env:SNYK_NIXOS_MCP_TOKEN}";
              startup_timeout_sec = 300;
            };
          };
        };
        programs.vscode = {
          enable = true;
          # Declare profiles without installing a Linux Code executable;
          # Windows remains the executable owner.
          package = lib.mkForce null;
          profiles = {
            default.enableMcpIntegration = true;
            Higi_LLP = {
              extensions = mkExtensions (defaultExtensionIds ++ pythonExtensionIds ++ higiExtensionIds);
              enableMcpIntegration = true;
            };
            Nix = {
              extensions = mkExtensions (
                defaultExtensionIds ++ pythonExtensionIds ++ fishExtensionIds ++ nixExtensionIds
              );
              enableMcpIntegration = true;
            };
            # Retain empty profile metadata even though WSL does not enable
            # these profiles' extension sets.
            Python = { };
            STM32 = { };
          };
        };
        home = {
          packages = [ syncScript ];
          # Keep Linux's extension tree empty. Windows Code owns the real
          # extension directory and receives the inventory on demand.
          file.".vscode/extensions".source = lib.mkForce pkgs.emptyDirectory;
          file.".config/Code/User/settings.json".text = builtins.toJSON (
            defaultProfileSettings
          );
          file.".config/Code/User/keybindings.json".text = builtins.toJSON [
            {
              key = "shift+[ArrowRight]";
              command = "workbench.action.nextEditor";
            }
            {
              key = "shift+[ArrowLeft]";
              command = "workbench.action.previousEditor";
            }
          ];
          file.".config/Code/User/profiles/Higi_LLP/settings.json".text = builtins.toJSON higiSettings;
          file.".config/Code/User/profiles/Higi_LLP/keybindings.json".text = builtins.toJSON [
            {
              key = "shift+[ArrowRight]";
              command = "workbench.action.nextEditor";
            }
            {
              key = "shift+[ArrowLeft]";
              command = "workbench.action.previousEditor";
            }
          ];
          file.".config/Code/User/profiles/Nix/settings.json".text = builtins.toJSON (
            defaultSettings
            // {
              "[python]"."editor.formatOnType" = true;
            }
          );
          file.".config/Code/User/profiles/Nix/keybindings.json".text = builtins.toJSON [
            {
              key = "shift+[ArrowRight]";
              command = "workbench.action.nextEditor";
            }
            {
              key = "shift+[ArrowLeft]";
              command = "workbench.action.previousEditor";
            }
          ];
          file.".config/Code/User/profiles/Nix/snippets/nix.json".text = builtins.toJSON {
            buildFirefoxXpiAddon = {
              prefix = [
                "buildFirefoxXpiAddon"
                "ffXpi"
              ];
              description = "Nix expression for building a Firefox XPI addon";
              body = [
                "= buildFirefoxXpiAddon {"
                "\tpname = \"$1\";"
                "\tversion = \"$2\";"
                "\taddonId = \"$3\";"
                "\turl = \"$4\";"
                "\tsha256 = \"\";"
                "\tmeta = with lib; { homepage = \"$5\"; description = \"$6\"; license = \"$7\"; mozPermissions = [$8]; platforms = platforms.all; };"
                "};"
              ];
            };
          };
          file.".config/Code/User/profiles/Nix/snippets/json.json".text = builtins.toJSON {
            DhcpReservation = {
              prefix = [ "reservation" ];
              description = "Kea/CoreDNS DHCP reservation";
              body = [
                "{"
                "  \"ip\": \"192.168.1.$0\","
                "  \"hostname\": \"$2\","
                "  \"mac\": \"$1\""
                "}"
              ];
            };
          };
        };
        home.activation.syncEditorToWindows =
          inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
            ''
              run ${lib.getExe syncScript}
            '';
      };
    };
}
