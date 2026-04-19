{
  flake.modules.homeManager.vscode =
    {
      config,
      lib,
      osConfig ? null,
      pkgs,
      ...
    }:
    let
      isWsl = (osConfig != null) && (osConfig.wsl.enable or false);
      context7ApiKeyPath =
        if config.sops.secrets ? context7_api_key then config.sops.secrets.context7_api_key.path else null;

      githubMcpTokenPath =
        if config.sops.secrets ? github_nixos_mcp_token then
          config.sops.secrets.github_nixos_mcp_token.path
        else
          null;

      patched-openssh = pkgs.openssh.overrideAttrs (prev: {
        patches = (prev.patches or [ ]) ++ [ ./openssh-nocheckcfg.patch ];
      });

      patchDesktopItems =
        items:
        lib.map (
          i:
          if i.meta.name == "code-url-handler.desktop" then
            i.overrideAttrs (
              final: prev: {
                text = lib.strings.replaceStrings [ "StartupWMClass=Code\n" ] [ "" ] prev.text;
              }
            )
          else
            i
        ) items;

      partyowl84-vscode = pkgs.vscode-partyowl84.overrideAttrs (prev: {
        buildInputs = (prev.buildInputs or [ ]) ++ [ patched-openssh ];
        desktopItems = patchDesktopItems prev.desktopItems;
      });

      synthwave-blues-vscode = pkgs.vscode-synthwave-blues.overrideAttrs (prev: {
        buildInputs = (prev.buildInputs or [ ]) ++ [ patched-openssh ];
        desktopItems = patchDesktopItems prev.desktopItems;
      });

      synthwave-84-vscode = pkgs.vscode-synthwave-84.overrideAttrs (prev: {
        buildInputs = (prev.buildInputs or [ ]) ++ [ patched-openssh ];
        desktopItems = patchDesktopItems prev.desktopItems;
      });

      selectedBakedTheme = "partyowl84";
      #selectedBakedTheme = "synthwave-blues";
      #selectedBakedTheme = "synthwave-84";

      bakedVscodeByName =
        name:
        {
          "partyowl84" = partyowl84-vscode;
          "synthwave-blues" = synthwave-blues-vscode;
          "synthwave-84" = synthwave-84-vscode;
        }
        .${name} or partyowl84-vscode;
      baseVscode = bakedVscodeByName selectedBakedTheme;
      vscodeWrapped = pkgs.symlinkJoin {
        pname = baseVscode.pname;
        version = baseVscode.version;
        name = baseVscode.name;
        paths = [ baseVscode ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          if [ -f "$out/bin/code" ]; then
            wrapProgram "$out/bin/code" \
              ${
                lib.optionalString (
                  githubMcpTokenPath != null
                ) "--run 'export GITHUB_NIXOS_MCP_TOKEN=\"$(cat ${githubMcpTokenPath})\"'"
              } \
              ${lib.optionalString (
                context7ApiKeyPath != null
              ) "--run 'export CONTEXT7_API_KEY=\"$(cat ${context7ApiKeyPath})\"'"}
          fi
          if [ -f "$out/bin/code-url-handler" ]; then
            wrapProgram "$out/bin/code-url-handler" \
              ${
                lib.optionalString (
                  githubMcpTokenPath != null
                ) "--run 'export GITHUB_NIXOS_MCP_TOKEN=\"$(cat ${githubMcpTokenPath})\"'"
              } \
              ${lib.optionalString (
                context7ApiKeyPath != null
              ) "--run 'export CONTEXT7_API_KEY=\"$(cat ${context7ApiKeyPath})\"'"}
          fi
        '';
      };

      bakedThemeSettings =
        {
          "partyowl84" = {
            "partyowl84.brightness" = 1;
            "partyowl84.disableGlow" = false;
            "workbench.colorTheme" = "Party Owl '84";
            "workbench.preferredDarkColorTheme" = "Party Owl '84";
            "editor.tokenColorCustomizations" = {
              "[Party Owl '84]" = {
                "textMateRules" = [
                  {
                    "scope" = [
                      "entity.other.attribute-name.nix"
                      "meta.attribute-key.nix"
                      "variable.other.object.nix"
                      "variable.other.object.parameter.nix"
                      "variable.other.object.property.nix"
                      "variable.parameter.function.nix"
                      "variable.parameter.nix"
                    ];
                    "settings" = {
                      "foreground" = "#C5E478";
                      "fontStyle" = "italic";
                    };
                  }
                  {
                    "scope" = [
                      "variable.interpolation"
                      "variable.other.normal.shell.nix"
                    ];
                    "settings" = {
                      "foreground" = "#ec5f67";
                    };
                  }
                  {
                    "scope" = [
                      "variable.language.special"
                      "variable.language.special.shell.nix"
                      "variable.parameter.positional.shell.nix"
                    ];
                    "settings" = {
                      "foreground" = "#8EACE3";
                    };
                  }
                ];
              };
            };
          };
          "synthwave-blues" = {
            "synthwave84blues.brightness" = 1;
            "synthwave84blues.disableGlow" = false;
            "workbench.colorTheme" = "Synthwave Blues";
            "workbench.preferredDarkColorTheme" = "Synthwave Blues";
            "editor.tokenColorCustomizations" = {
              "[Synthwave Blues]" = {
                "textMateRules" = [
                  {
                    "scope" = [
                      "entity.other.attribute-name.nix"
                      "meta.attribute-key.nix"
                      "variable.other.object.nix"
                      "variable.other.object.parameter.nix"
                      "variable.other.object.property.nix"
                      "variable.parameter.function.nix"
                      "variable.parameter.nix"
                    ];
                    "settings" = {
                      "foreground" = "#C5E478";
                      "fontStyle" = "italic";
                    };
                  }
                  {
                    "scope" = [
                      "variable.interpolation"
                      "variable.other.normal.shell.nix"
                    ];
                    "settings" = {
                      "foreground" = "#ec5f67";
                    };
                  }
                  {
                    "scope" = [
                      "variable.language.special"
                      "variable.language.special.shell.nix"
                      "variable.parameter.positional.shell.nix"
                    ];
                    "settings" = {
                      "foreground" = "#8EACE3";
                    };
                  }
                ];
              };
            };
          };
          "synthwave-84" = {
            "synthwave84.brightness" = 1;
            "synthwave84.disableGlow" = false;
            "workbench.colorTheme" = "SynthWave 84";
            "workbench.preferredDarkColorTheme" = "SynthWave 84";
            "editor.tokenColorCustomizations" = {
              "[SynthWave 84]" = {
                "textMateRules" = [
                  {
                    "scope" = [
                      "entity.other.attribute-name.nix"
                      "meta.attribute-key.nix"
                      "variable.other.object.nix"
                      "variable.other.object.parameter.nix"
                      "variable.other.object.property.nix"
                      "variable.parameter.function.nix"
                      "variable.parameter.nix"
                    ];
                    "settings" = {
                      "foreground" = "#C5E478";
                      "fontStyle" = "italic";
                    };
                  }
                  {
                    "scope" = [
                      "variable.interpolation"
                      "variable.other.normal.shell.nix"
                    ];
                    "settings" = {
                      "foreground" = "#ec5f67";
                    };
                  }
                  {
                    "scope" = [
                      "variable.language.special"
                      "variable.language.special.shell.nix"
                      "variable.parameter.positional.shell.nix"
                    ];
                    "settings" = {
                      "foreground" = "#8EACE3";
                    };
                  }
                ];
              };
            };
          };
        }
        .${selectedBakedTheme} or { };

      remoteExts = [
        "ms-vscode.remote-explorer"
        "ms-vscode-remote.remote-containers"
        "ms-vscode-remote.remote-ssh"
        "ms-vscode-remote.remote-ssh-edit"
        "ms-vscode-remote.remote-wsl"
      ];

      uiExts = [
        "esbenp.prettier-vscode"
        "evondev.indent-rainbow-palettes"
        "oderwat.indent-rainbow"
        "rimuruchan.vscode-fix-checksums-next"
        "sabrsorensen.party-owl-84"
        "sabrsorensen.synthwave-blues"
        "vscodevim.vim"
      ];

      copilotExts = [
        "github.copilot"
        "github.copilot-chat"
      ];

      gitHubExts = [
        "github.vscode-github-actions"
      ];

      defaultExts = [
        "docker.docker"
        "ms-azuretools.vscode-containers"
        "rangav.vscode-thunder-client"
        "redhat.vscode-yaml"
        "tomoki1207.pdf"
      ]
      ++ uiExts
      ++ copilotExts
      ++ nixExts
      ++ remoteExts;

      higiExts = [
        "openai.chatgpt"
        "snyk-security.snyk-vulnerability-scanner"
      ]
      ++ pulumiExts;

      nixExts = [
        "jeff-hykin.better-nix-syntax"
        "LiemLB.nix-flakes"
      ];

      pulumiExts = [
        "pulumi.pulumi-vscode-tools"
      ];

      pythonExts = [
        "ms-python.debugpy"
        "ms-python.python"
        "ms-python.vscode-pylance"
      ];

      cSharpExts = with pkgs.vscode-extensions; [
        ms-dotnettools.csharp
        ms-dotnettools.csdevkit
        ms-dotnettools.vscode-dotnet-runtime
      ];

      sqlExts = [
        "ms-mssql.mssql"
        "ms-ossdata.vscode-pgsql"
      ];

      defaultKeyBindings = [
        {
          "key" = "shift+[ArrowRight]";
          "command" = "workbench.action.nextEditor";
        }
        {
          "key" = "shift+[ArrowLeft]";
          "command" = "workbench.action.previousEditor";
        }
      ];

      defaultProfileOnlySettings = {
        "extensions.supportUntrustedWorkspaces" = {
          "sabrsorensen.party-owl-84" = {
            "supported" = true;
          };
          "vscodevim.vim" = {
            "supported" = true;
          };
        };
        "remote.SSH.experimental.chat" = false;
        "remote.SSH.remotePlatform" = {
          "Omnius" = "linux";
          "AtlasUponRaiden" = "linux";
          "EmeraldEcho" = "linux";
        };
        "remote.SSH.showLoginTerminal" = false;
        "remote.SSH.useLocalServer" = true;
        "settingsSync.keybindingsPerPlatform" = false;
        "settingsSync.ignoredSettings" = [ "*" ];
        "telemetry.telemetryLevel" = "off";
        "vim.insertModeKeyBindings" = [
          {
            "before" = [
              "j"
              "j"
            ];
            "after" = [ "<Esc>" ];
          }
        ];
        "vim.normalModeKeyBindings" = [
          {
            "before" = [ "0" ];
            "after" = [ "^" ];
          }
        ];
        "vim.visualModeKeyBindingsNonRecursive" = [
          {
            "before" = [ ">" ];
            "commands" = [ "editor.action.indentLines" ];
          }
          {
            "before" = [ "<" ];
            "commands" = [ "editor.action.outdentLines" ];
          }
        ];
        "window.newWindowDimensions" = "maximized";
        "window.newWindowProfile" = "Default";
        "window.restoreWindows" = "none";
      };

      copilotSettings = {
        "chat.agent.enabled" = true;
        "chat.commandCenter.enabled" = true;
        "chat.mcp.gallery.enabled" = true;
        "chat.viewSessions.orientation" = "stacked";
        "github.copilot.editor.enableCodeActions" = true;
        "github.copilot.nextEditSuggestions.enabled" = true;
      };

      defaultUserSettings = {
        "[dockercompose]" = {
          "editor.autoIndent" = "advanced";
          "editor.defaultFormatter" = "redhat.vscode-yaml";
          "editor.insertSpaces" = true;
          "editor.quickSuggestions" = {
            "comments" = false;
            "other" = true;
            "strings" = true;
          };
          "editor.tabSize" = 2;
        };
        "[github-actions-workflow]" = {
          "editor.defaultFormatter" = "redhat.vscode-yaml";
        };
        "[json]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[jsonc]" = {
          "editor.defaultFormatter" = "vscode.json-language-features";
        };
        "accessibility.signals.terminalBell" = {
          "sound" = "on";
        };
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
          "other" = "inline";
          "comments" = false;
          "strings" = false;
        };
        "editor.renderControlCharacters" = true;
        "editor.renderWhitespace" = "boundary";
        "editor.suggest.localityBonus" = true;
        "editor.suggest.shareSuggestSelections" = true;
        "editor.tabCompletion" = "on";
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
        "remote.env" = {
          "NODE_EXTRA_CA_CERTS" = "/etc/ssl/certs/ca-bundle.crt";
        };
        "remote.extensionKind" = {
          "oderwat.indent-rainbow" = [ "ui" ];
        };
        "search.showLineNumbers" = true;
        "search.smartCase" = true;
        "terminal.integrated.copyOnSelection" = true;
        "terminal.integrated.cursorBlinking" = true;
        "terminal.integrated.defaultProfile.linux" = "fish";
        "terminal.integrated.defaultProfile.windows" = "NixOS (WSL)";
        "terminal.integrated.enableVisualBell" = true;
        "terminal.integrated.fontFamily" = "CaskaydiaCove Nerd Font Mono";
        "terminal.integrated.fontLigatures.enabled" = true;
        "terminal.integrated.profiles.windows" = {
          "PowerShell" = {
            "source" = "PowerShell";
            "icon" = "terminal-powershell";
          };
          "Command Prompt" = {
            "path" = [
              "\${env =windir}\\Sysnative\\cmd.exe"
              "\${env =windir}\\System32\\cmd.exe"
            ];
            "args" = [ ];
            "icon" = "terminal-cmd";
          };
          "NixOS (WSL)" = {
            "path" = "C =\\windows\\System32\\wsl.exe";
            "args" = [
              "-d"
              "NixOS"
            ];
          };
        };
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
        "workbench.editor.highlightModifiedTabs" = true;
        "workbench.editor.revealIfOpen" = true;
      }
      // bakedThemeSettings
      // copilotSettings;

      dotnetSettings = {
        "dotnetAcquisitionExtension.sharedExistingDotnetPath" = "/run/current-system/sw/bin/dotnet";
        "dotnetAcquisitionExtension.allowInvalidPaths" = true;
      };

      higiSettings = {
        "extensions.verifySignature" = false; # NixOS WSL remote server signing issue
        "chatgpt.runCodexInWindowsSubsystemForLinux" = true;
        "snyk.advanced.cliPath" = "C:\\Users\\ssorensen\\AppData\\Local\\snyk\\vscode-cli\\snyk-win.exe";
        "snyk.securityAtInception.autoConfigureSnykMcpServer" = true;
        "snyk.securityAtInception.executionFrequency" = "On Code Generation";
      };

      nixSettings = {
        "[nix]" = {
          "editor.tabSize" = 2;
          "editor.indentSize" = "tabSize";
        };
      };

      pythonSettings = {
        "[python]" = {
          "editor.formatOnType" = true;
        };
      };
    in
    {
      home.packages = lib.optionals (!isWsl) [ pkgs.dotnetCorePackages.sdk_10_0-bin ];
      programs.vscode = {
        enable = true;
        #mutableExtsDir = true; # mutually exclusive with profiles
        #package = lib.mkDefault (pkgs.vscode.fhsWithPackages (_: [ patched-openssh ]);
        # To use a different baked version, set:
        package = vscodeWrapped;
        #package = bakedVscodeByName "synthwave-blues";
        profiles = {
          default = {
            enableExtensionUpdateCheck = true;
            enableUpdateCheck = true;
            keybindings = defaultKeyBindings ++ [
              #{
              #  "key" = "ctrl+alt+f";
              #  "command" = "editor.action.insertSnippet";
              #  "args" = {
              #    "snippet" = "$LINE_COMMENT FIXME: $0";
              #  };
              #},
              #{
              #    key = "ctrl+c";
              #    command = "editor.action.clipboardCopyAction";
              #    when = "textInputFocus";
              #}
            ];
            globalSnippets = {
              #fixme = {
              #  prefix = [ "fixme" ];
              #  body = [ "$LINE_COMMENT FIXME: $0" ];
              #  description = "Insert a FIXME remark";
              #};
            };
            languageSnippets = {
              #languageName = {
              #  fixme = {
              #    prefix = [ "fixme" ];
              #    body = [ "$LINE_COMMENT FIXME: $0" ];
              #    description = "Insert a FIXME remark";
              #  };
              #};
            };
            userSettings = defaultProfileOnlySettings // defaultUserSettings;
            extensions = pkgs.nix4vscode.forVscodeVersion vscodeWrapped.version (
              defaultExts
              ++ pythonExts
              ++ [
                "bmalehorn.vscode-fish"
              ]
            );
            enableMcpIntegration = true;
          };
          #CSharp_dotNET = {
          #  extensions =
          #    cSharpExts ++
          #    pkgs.nix4vscode.forVscodeVersion vscodeWrapped.version (
          #      defaultExts ++ [
          #      ]
          #    );
          #  keybindings = defaultKeyBindings ++ [];
          #  languageSnippets = { };
          #  userSettings = dotnetSettings // defaultUserSettings;
          #};
          Higi_LLP = {
            extensions = pkgs.nix4vscode.forVscodeVersion vscodeWrapped.version (
              higiExts
              ++ pythonExts
              ++ sqlExts
              ++ gitHubExts
              ++ defaultExts
              ++ [
              ]
            );
            keybindings = defaultKeyBindings ++ [ ];
            languageSnippets = { };
            userSettings = defaultUserSettings // higiSettings // { };
            enableMcpIntegration = true;
          };
          Nix = {
            extensions = pkgs.nix4vscode.forVscodeVersion vscodeWrapped.version (
              defaultExts
              ++ pythonExts
              ++ [
                "bmalehorn.vscode-fish"
                "signageos.signageos-vscode-sops"
              ]
            );
            keybindings = defaultKeyBindings ++ [ ];
            languageSnippets = {
              nix = {
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
                    "\tmeta = with lib;"
                    "\t{"
                    "\t\thomepage = \"$5\";"
                    "\t\tdescription = \"$6\";"
                    "\t\tlicense = \"$7\";"
                    "\t\tmozPermissions = [$8];"
                    "\t\tplatforms = platforms.all;"
                    "\t};"
                    "};"
                  ];
                };
              };
              json = {
                AdGuardHomeStaticLease = {
                  prefix = [ "lease" ];
                  description = "AdGuard Home static lease";
                  body = [
                    "{"
                    "  \"expires\": \"\","
                    "  \"ip\": \"192.168.1.$0\","
                    "  \"hostname\": \"$2\","
                    "  \"mac\": \"$1\","
                    "  \"static\": true"
                    "},"
                  ];
                };
              };
            };
            userSettings = nixSettings // pythonSettings // defaultUserSettings;
            enableMcpIntegration = true;
          };

          #RustTauri = {
          #  extensions =
          #    pkgs.nix4vscode.forVscodeVersion vscodeWrapped.version (
          #      defaultExts ++
          #      pythonExts ++ [
          #        # Tauri
          #        "tauri-apps.tauri-vscode"
          #        # Rust
          #        "rust-lang.rust-analyzer"
          #        "fill-labs.dependi"
          #        "vadimcn.vscode-lldb"
          #        "tamasfe.even-better-toml"
          #        # Flatpak
          #        "bilelmoussaoui.flatpak-vscode"
          #        # GitHub Actions
          #        "github.vscode-github-actions"
          #        # Nix
          #        "jeff-hykin.better-nix-syntax"
          #      ]
          #    );
          #  keybindings = defaultKeyBindings ++ [];
          #  languageSnippets = { };
          #  userSettings = {
          #    #"rust-analyzer.checkOnSave.command" = "clippy";
          #    "rust-analyzer.cargo.allFeatures" = true;
          #    "rust-analyzer.procMacro.enable" = true;
          #    "tauri.enableAutoReload" = true;
          #    "flatpak.sdk" = "org.freedesktop.Sdk";
          #    "flatpak.runtime" = "org.freedesktop.Platform";
          #    "github-actions.workflows.pinned" = true;
          #  } // defaultUserSettings;
          #};

          Python = {
            extensions = pkgs.nix4vscode.forVscodeVersion vscodeWrapped.version (
              defaultExts
              ++ pythonExts
              ++ [
              ]
            );
            keybindings = defaultKeyBindings ++ [ ];
            languageSnippets = { };
            userSettings = pythonSettings // defaultUserSettings;
            enableMcpIntegration = true;
          };
          #StardewValley = {
          #  extensions =
          #    cSharpExts ++
          #    pkgs.nix4vscode.forVscodeVersion vscodeWrapped.version (
          #      defaultExts ++ [
          #        "atlasv.sdvdeployandpack"
          #        "taelfayre.stardew-snippets"
          #      ]
          #    );
          #  keybindings = defaultKeyBindings ++ [];
          #  languageSnippets = { };
          #  userSettings = dotnetSettings // defaultUserSettings;
          #};
          STM32 = {
            extensions =
              pkgs.nix4vscode.forVscodeVersion vscodeWrapped.version (
                defaultExts ++ [
                  "ms-vscode.cpptools"
                  "ms-vscode.cpptools-extension-pack"
                  "platformio.platformio-ide"
                ]
              );
            keybindings = defaultKeyBindings ++ [];
            languageSnippets = { };
            userSettings = defaultUserSettings;
          };
        };
      };
    };
}
