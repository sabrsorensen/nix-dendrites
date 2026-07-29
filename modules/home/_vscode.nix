{ inputs }:
{
  # Keep editor packages and Marketplace extension resolution as a normal,
  # self-gating broadcast capability.  The WSL profile continues to manage the
  # Windows-side editor separately.
  flake.modules.nixos.vscode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      host = config.my.host;
      cfg = config.my.editor;
      theme = host.vscodeTheme;
      baseThemePackage =
        {
          partyowl84 = {
            vscode =
              inputs.partyowl84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscode-partyowl84;
            vscodium =
              inputs.partyowl84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscodium-partyowl84;
          };
          synthwave-blues = {
            vscode =
              inputs.synthwave-blues-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscode-synthwave-blues;
            vscodium =
              inputs.synthwave-blues-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscodium-synthwave-blues;
          };
          synthwave-84 = {
            vscode =
              inputs.synthwave-84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscode-synthwave84;
            vscodium =
              inputs.synthwave-84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscodium-synthwave84;
          };
        }
        .${theme}.${cfg.packageFlavor};
      product =
        {
          vscode = {
            binaryName = "code";
            urlHandlerBinaryName = "code-url-handler";
            urlHandlerDesktopName = "code-url-handler.desktop";
          };
          vscodium = {
            binaryName = "codium";
            urlHandlerBinaryName = "codium-url-handler";
            urlHandlerDesktopName = "codium-url-handler.desktop";
          };
        }
        .${cfg.packageFlavor};
      patchedOpenSsh = pkgs.openssh.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./openssh-nocheckcfg.patch ];
      });
      patchDesktopItems =
        items:
        map (
          item:
          if item.meta.name == product.urlHandlerDesktopName then
            item.overrideAttrs (
              _: prev: {
                text =
                  builtins.replaceStrings [ "StartupWMClass=Code\n" "StartupWMClass=VSCodium\n" ] [ "" "" ]
                    prev.text;
              }
            )
          else
            item
        ) items;
      editorPackage = baseThemePackage.overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ patchedOpenSsh ];
        desktopItems = patchDesktopItems old.desktopItems;
      });
      editorSecretExports =
        lib.concatMapStringsSep "\n"
          (secret: ''
            if [ -r ${lib.escapeShellArg secret.path} ]; then
              export ${secret.name}="$(cat ${lib.escapeShellArg secret.path})"
            fi
          '')
          [
            {
              name = "GITHUB_NIXOS_MCP_TOKEN";
              path = config.home-manager.users.sam.sops.secrets.github_nixos_mcp_token.path;
            }
            {
              name = "CONTEXT7_API_KEY";
              path = config.home-manager.users.sam.sops.secrets.context7_api_key.path;
            }
          ];
      themePackage = pkgs.symlinkJoin {
        name = "${baseThemePackage.pname or baseThemePackage.name}-wrapped";
        paths = [ editorPackage ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          for binary in ${product.binaryName} ${product.urlHandlerBinaryName}; do
            if [ -f "$out/bin/$binary" ]; then
              wrapProgram "$out/bin/$binary" --run ${lib.escapeShellArg editorSecretExports}
            fi
          done
        '';
      };
      nixThemeTokenColorCustomizations =
        themeName:
        {
          "[${themeName}]" = {
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
                "settings"."foreground" = "#ec5f67";
              }
              {
                "scope" = [
                  "variable.language.special"
                  "variable.language.special.shell.nix"
                  "variable.parameter.positional.shell.nix"
                ];
                "settings"."foreground" = "#8EACE3";
              }
            ];
          };
        };
      themeSettings =
        {
          partyowl84 = {
            "partyowl84.brightness" = 1;
            "partyowl84.disableGlow" = false;
            "workbench.colorTheme" = "Party Owl '84";
            "workbench.preferredDarkColorTheme" = "Party Owl '84";
            "editor.tokenColorCustomizations" = nixThemeTokenColorCustomizations "Party Owl '84";
          };
          synthwave-blues = {
            "synthwave84blues.brightness" = 1;
            "synthwave84blues.disableGlow" = false;
            "workbench.colorTheme" = "Synthwave Blues";
            "workbench.preferredDarkColorTheme" = "Synthwave Blues";
            "editor.tokenColorCustomizations" = nixThemeTokenColorCustomizations "Synthwave Blues";
          };
          synthwave-84 = {
            "synthwave84.brightness" = 1;
            "synthwave84.disableGlow" = false;
            "workbench.colorTheme" = "SynthWave 84";
            "workbench.preferredDarkColorTheme" = "SynthWave 84";
            "editor.tokenColorCustomizations" = nixThemeTokenColorCustomizations "SynthWave 84";
          };
        }
        .${theme};
      mkExtensions =
        extensions:
        let
          marketplaceExtensions = builtins.filter builtins.isString extensions;
          explicitExtensions = builtins.filter (extension: !builtins.isString extension) extensions;
        in
        pkgs.nix4vscode.forVscodeVersion (baseThemePackage.vscodeVersion or baseThemePackage.version
        ) marketplaceExtensions
        ++ explicitExtensions;
      openVsxExtension =
        {
          publisher,
          name,
          version,
          sha256,
          url,
        }:
        pkgs.vscode-utils.buildVscodeExtension {
          inherit version;
          pname = "${publisher}-${name}";
          src = pkgs.fetchurl {
            inherit url sha256;
          };
          vscodeExtPublisher = publisher;
          vscodeExtName = name;
          vscodeExtUniqueId = "${publisher}.${name}";
        };
      vscodiumDevpodContainers = openVsxExtension {
        publisher = "3timeslazy";
        name = "vscodium-devpodcontainers";
        version = "0.0.18";
        sha256 = "156nv9xvdsbq4782d0lpg7pjm45zi36ga6d7prv2lb844jsbli22";
        url = "https://open-vsx.org/api/3timeslazy/vscodium-devpodcontainers/0.0.18/file/3timeslazy.vscodium-devpodcontainers-0.0.18.vsix";
      };
      openRemoteWsl = openVsxExtension {
        publisher = "jeanp413";
        name = "open-remote-wsl";
        version = "0.0.5";
        sha256 = "0md3fmchsk5948n748m7j1zmj3hqjxy1vwbbhyrfk8pp5j55s0pi";
        url = "https://open-vsx.org/api/jeanp413/open-remote-wsl/0.0.5/file/jeanp413.open-remote-wsl-0.0.5.vsix";
      };
      openRemoteSsh = openVsxExtension {
        publisher = "jeanp413";
        name = "open-remote-ssh";
        version = "0.1.2";
        sha256 = "10ankbl6gfbrgc5ghj5744g1n66cx1vpr9bbmkp1k89m9m40ahsc";
        url = "https://open-vsx.org/api/jeanp413/open-remote-ssh/0.1.2/file/jeanp413.open-remote-ssh-0.1.2.vsix";
      };
      remoteExtensions =
        if cfg.packageFlavor == "vscode" then
          [
            "ms-vscode.remote-explorer"
            "ms-vscode-remote.remote-containers"
            "ms-vscode-remote.remote-ssh"
            "ms-vscode-remote.remote-ssh-edit"
            "ms-vscode-remote.remote-wsl"
          ]
        else
          [ "ms-vscode.remote-explorer" ]
          ++ [
            vscodiumDevpodContainers
            openRemoteSsh
            openRemoteWsl
          ];
      defaultExtensionIds = [
        "docker.docker"
        "esbenp.prettier-vscode"
        "evondev.indent-rainbow-palettes"
        "github.vscode-github-actions"
        "humao.rest-client"
        "jeff-hykin.better-nix-syntax"
        "LiemLB.nix-flakes"
        "ms-azuretools.vscode-containers"
        "oderwat.indent-rainbow"
        "redhat.vscode-yaml"
        "rimuruchan.vscode-fix-checksums-next"
        "sabrsorensen.party-owl-84"
        "sabrsorensen.synthwave-blues"
        "tomoki1207.pdf"
        "vscodevim.vim"
      ]
      ++ remoteExtensions;
      pythonExtensionIds = [
        "ms-python.debugpy"
        "ms-python.python"
        "ms-python.vscode-pylance"
      ];
      fishExtensionIds = [ "bmalehorn.vscode-fish" ];
      nixExtensionIds = [ "signageos.signageos-vscode-sops" ];
      stm32ExtensionIds = [
        "eclipse-cdt.memory-inspector"
        "eclipse-cdt.serial-monitor"
        "ms-vscode.cmake-tools"
        "platformio.platformio-ide"
        "stmicroelectronics.stm32-vscode-extension"
        "stmicroelectronics.stm32cube-ide-build-analyzer"
        "stmicroelectronics.stm32cube-ide-build-cmake"
        "stmicroelectronics.stm32cube-ide-bundles-manager"
        "stmicroelectronics.stm32cube-ide-clangd"
        "stmicroelectronics.stm32cube-ide-core"
        "stmicroelectronics.stm32cube-ide-debug-core"
        "stmicroelectronics.stm32cube-ide-debug-generic-gdbserver"
        "stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver"
        "stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver"
        "stmicroelectronics.stm32cube-ide-project-manager"
        "stmicroelectronics.stm32cube-ide-registers"
        "stmicroelectronics.stm32cube-ide-rtos"
      ];
      higiExtensionIds = [
        "openai.chatgpt"
        "snyk-security.snyk-vulnerability-scanner"
        "pulumi.pulumi-vscode-tools"
        "ms-mssql.mssql"
        "ms-ossdata.vscode-pgsql"
      ];
      defaultExtensions = mkExtensions (defaultExtensionIds ++ pythonExtensionIds ++ fishExtensionIds);
      nixExtensions = mkExtensions (
        defaultExtensionIds ++ pythonExtensionIds ++ fishExtensionIds ++ nixExtensionIds
      );
      pythonExtensions = mkExtensions (defaultExtensionIds ++ pythonExtensionIds);
      stm32Extensions = mkExtensions (defaultExtensionIds ++ stm32ExtensionIds);
      higiExtensions = mkExtensions (
        higiExtensionIds ++ pythonExtensionIds ++ [ "github.vscode-github-actions" ] ++ defaultExtensionIds
      );
      defaultKeybindings = [
        {
          key = "shift+[ArrowRight]";
          command = "workbench.action.nextEditor";
        }
        {
          key = "shift+[ArrowLeft]";
          command = "workbench.action.previousEditor";
        }
      ];
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
          "editor.indentSize" = "tabSize";
          "editor.tabSize" = 2;
        };
        "chat.disableAIFeatures" = true;
        "accessibility.signals.terminalBell"."sound" = "on";
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
          reportMissingParameterType = "warning";
          reportUnknownArgumentType = "warning";
          reportUnknownMemberType = "warning";
          reportUnknownParameterType = "warning";
          reportUnknownVariableType = "warning";
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
        "vim.sneak" = true;
        "vim.smartcase" = true;
        "vim.surround" = true;
        "vim.useCtrlKeys" = true;
        "vim.useSystemClipboard" = false;
        "window.commandCenter" = true;
        "workbench.editor.highlightModifiedTabs" = true;
        "workbench.editor.revealIfOpen" = true;
      }
      // themeSettings;
      editorProgram = {
        enable = true;
        package = themePackage;
        profiles.default = {
          enableExtensionUpdateCheck = true;
          enableUpdateCheck = true;
          extensions = defaultExtensions;
          enableMcpIntegration = true;
          keybindings = defaultKeybindings;
          userSettings = defaultSettings // {
            "extensions.supportUntrustedWorkspaces" = {
              "sabrsorensen.party-owl-84".supported = true;
              "vscodevim.vim".supported = true;
            };
            "remote.SSH.remotePlatform" = {
              AtlasUponRaiden = "linux";
              EmeraldEcho = "linux";
              Kamino = "linux";
              Naboo = "linux";
              Nevarro = "linux";
              ZaphodBeeblebrox = "linux";
            };
            "remote.SSH.experimental.chat" = false;
            "remote.SSH.showLoginTerminal" = false;
            "remote.SSH.useLocalServer" = true;
            "settingsSync.keybindingsPerPlatform" = false;
            "settingsSync.ignoredSettings" = [ "*" ];
            "telemetry.telemetryLevel" = "off";
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
            "window.newWindowDimensions" = "maximized";
            "window.newWindowProfile" = "Default";
            "window.restoreWindows" = "none";
          };
        };
        profiles = {
          Higi_LLP =
            if cfg.profiles.higiLlp then
              {
                extensions = higiExtensions;
                enableMcpIntegration = true;
                keybindings = defaultKeybindings;
                userSettings =
                  defaultSettings
                  // {
                    "extensions.verifySignature" = false;
                    "snyk.advanced.cliPath" = "C:\\Users\\ssorensen\\AppData\\Local\\snyk\\vscode-cli\\snyk-win.exe";
                    "snyk.securityAtInception.autoConfigureSnykMcpServer" = true;
                    "snyk.securityAtInception.executionFrequency" = "On Code Generation";
                  }
                  // lib.optionalAttrs cfg.higi.runCodexInWsl {
                    "chatgpt.runCodexInWindowsSubsystemForLinux" = true;
                  };
              }
            else
              { };
          Nix = {
            extensions = nixExtensions;
            enableMcpIntegration = true;
            keybindings = defaultKeybindings;
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
            userSettings = defaultSettings // {
              "[nix]" = {
                "editor.tabSize" = 2;
                "editor.indentSize" = "tabSize";
              };
              "[python]"."editor.formatOnType" = true;
              "editor.formatOnSave" = true;
            };
          };
          Python =
            if cfg.profiles.python then
              {
                extensions = pythonExtensions;
                enableMcpIntegration = true;
                keybindings = defaultKeybindings;
                userSettings = defaultSettings // {
                  "[python]"."editor.formatOnType" = true;
                  "python.analysis.typeCheckingMode" = "strict";
                  "editor.formatOnSave" = true;
                };
              }
            else
              { };
          STM32 =
            if cfg.profiles.stm32 then
              {
                extensions = stm32Extensions;
                keybindings = defaultKeybindings;
                userSettings = defaultSettings // {
                  "stm32cube-ide-core.configuration.productSTM32CubeMX.executablePath" =
                    "/etc/profiles/per-user/sam/bin/stm32cubemx";
                  "stm32cube-ide-core.enableTelemetry" = false;
                  "editor.formatOnSave" = true;
                };
              }
            else
              { };
        };
      };
    in
    {
      options.my.editor = {
        packageFlavor = lib.mkOption {
          type = lib.types.enum [
            "vscode"
            "vscodium"
          ];
          default = "vscodium";
          description = "Editor package family used for managed profiles.";
        };
        installLocalDotnetSdk = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install the local .NET SDK used by managed editor profiles.";
        };
        profiles = {
          higiLlp = lib.mkEnableOption "the Higi LLP editor profile";
          python = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "the Python editor profile";
          };
          stm32 = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "the STM32 editor profile";
          };
        };
        higi.runCodexInWsl = lib.mkEnableOption "running Codex in WSL from the Higi LLP profile";
      };

      config = lib.mkIf (host.features.vscode && host.home.enable) {
        nixpkgs.overlays = [ inputs.nix4vscode.overlays.forVscode ];
        home-manager.users.sam = {
          home.packages =
            lib.optionals cfg.installLocalDotnetSdk [ pkgs.dotnetCorePackages.sdk_10_0-bin ]
            ++ lib.optionals cfg.profiles.stm32 [ pkgs.stm32cubemx ];
          programs =
            lib.optionalAttrs (cfg.packageFlavor == "vscode") { vscode = editorProgram; }
            // lib.optionalAttrs (cfg.packageFlavor == "vscodium") { vscodium = editorProgram; };
        };
      };
    };
}
