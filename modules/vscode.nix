{ inputs, ... }:
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
      theme = host.vscodeTheme;
      themePackage =
        {
          partyowl84 =
            inputs.partyowl84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscodium-partyowl84;
          synthwave-blues =
            inputs.synthwave-blues-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscodium-synthwave-blues;
          synthwave-84 =
            inputs.synthwave-84-vscode-theme.packages.${pkgs.stdenv.hostPlatform.system}.vscodium-synthwave84;
        }
        .${theme};
      themeSettings =
        {
          partyowl84 = {
            "partyowl84.brightness" = 1;
            "partyowl84.disableGlow" = false;
            "workbench.colorTheme" = "Party Owl '84";
            "workbench.preferredDarkColorTheme" = "Party Owl '84";
          };
          synthwave-blues = {
            "synthwave84blues.brightness" = 1;
            "synthwave84blues.disableGlow" = false;
            "workbench.colorTheme" = "Synthwave Blues";
            "workbench.preferredDarkColorTheme" = "Synthwave Blues";
          };
          synthwave-84 = {
            "synthwave84.brightness" = 1;
            "synthwave84.disableGlow" = false;
            "workbench.colorTheme" = "SynthWave 84";
            "workbench.preferredDarkColorTheme" = "SynthWave 84";
          };
        }
        .${theme};
      mkExtensions =
        ids: pkgs.nix4vscode.forVscodeVersion (themePackage.vscodeVersion or themePackage.version) ids;
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
      remoteExtensions = mkExtensions [ "ms-vscode.remote-explorer" ] ++ [
        vscodiumDevpodContainers
        openRemoteSsh
        openRemoteWsl
      ];
      defaultExtensions =
        mkExtensions [
          "bmalehorn.vscode-fish"
          "docker.docker"
          "esbenp.prettier-vscode"
          "evondev.indent-rainbow-palettes"
          "github.vscode-github-actions"
          "humao.rest-client"
          "jeff-hykin.better-nix-syntax"
          "LiemLB.nix-flakes"
          "ms-azuretools.vscode-containers"
          "ms-python.debugpy"
          "ms-python.python"
          "ms-python.vscode-pylance"
          "oderwat.indent-rainbow"
          "redhat.vscode-yaml"
          "rimuruchan.vscode-fix-checksums-next"
          "sabrsorensen.party-owl-84"
          "sabrsorensen.synthwave-blues"
          "tomoki1207.pdf"
          "vscodevim.vim"
        ]
        ++ remoteExtensions;
      pythonExtensions = mkExtensions [
        "ms-python.debugpy"
        "ms-python.python"
        "ms-python.vscode-pylance"
      ];
      nixExtensions = mkExtensions [
        "jeff-hykin.better-nix-syntax"
        "LiemLB.nix-flakes"
        "signageos.signageos-vscode-sops"
      ];
      stm32Extensions = mkExtensions [
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
        "debug.toolBarLocation" = "commandCenter";
        "docker.extension.enableComposeLanguageServer" = true;
        "editor.bracketPairColorization.enabled" = true;
        "editor.fontFamily" = "CaskaydiaCove Nerd Font Mono";
        "editor.fontLigatures" = true;
        "editor.formatOnSave" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.guides.bracketPairsHorizontal" = true;
        "editor.renderControlCharacters" = true;
        "editor.renderWhitespace" = "boundary";
        "editor.tabCompletion" = "on";
        "editor.tabSize" = 2;
        "explorer.confirmDelete" = false;
        "explorer.openEditors.visible" = 10;
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
        "python.analysis.indexing" = true;
        "python.analysis.typeCheckingMode" = "strict";
        "python.analysis.useLibraryCodeForTypes" = true;
        "python.languageServer" = "Pylance";
        "redhat.telemetry.enabled" = false;
        "remote.env"."NODE_EXTRA_CA_CERTS" = "/etc/ssl/certs/ca-bundle.crt";
        "remote.SSH.experimental.chat" = false;
        "remote.SSH.showLoginTerminal" = false;
        "remote.SSH.useLocalServer" = true;
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
        "vim.sneak" = true;
        "vim.smartcase" = true;
        "vim.surround" = true;
        "vim.useCtrlKeys" = true;
        "vim.useSystemClipboard" = false;
        "window.commandCenter" = true;
        "window.newWindowDimensions" = "maximized";
        "window.newWindowProfile" = "Default";
        "window.restoreWindows" = "none";
        "workbench.editor.highlightModifiedTabs" = true;
        "workbench.editor.revealIfOpen" = true;
      }
      // themeSettings;
    in
    lib.mkIf host.features.vscode {
      nixpkgs.overlays = [ inputs.nix4vscode.overlays.forVscode ];
      home-manager.users.sam = {
        # The predecessor installed the editor's local .NET SDK and
        # STM32CubeMX alongside these profiles.  Profiles alone only provide
        # extensions and settings, leaving the executable path dangling.
        home.packages = [
          pkgs.dotnetCorePackages.sdk_10_0-bin
          pkgs.stm32cubemx
        ];
        programs.vscodium = {
          enable = true;
          package = themePackage;
          profiles.default = {
            enableExtensionUpdateCheck = true;
            enableUpdateCheck = true;
            extensions = defaultExtensions;
            enableMcpIntegration = true;
            keybindings = [
              {
                key = "shift+[ArrowRight]";
                command = "workbench.action.nextEditor";
              }
              {
                key = "shift+[ArrowLeft]";
                command = "workbench.action.previousEditor";
              }
            ];
            userSettings = defaultSettings // {
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
            };
          };
          profiles = {
            Nix = {
              extensions = defaultExtensions ++ nixExtensions;
              enableMcpIntegration = true;
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
                "editor.formatOnSave" = true;
              };
            };
            Python = {
              extensions = defaultExtensions ++ pythonExtensions;
              enableMcpIntegration = true;
              userSettings = defaultSettings // {
                "[python]"."editor.formatOnType" = true;
                "python.analysis.typeCheckingMode" = "strict";
                "editor.formatOnSave" = true;
              };
            };
            STM32 = {
              extensions = defaultExtensions ++ stm32Extensions;
              enableMcpIntegration = true;
              userSettings = defaultSettings // {
                "stm32cube-ide-core.configuration.productSTM32CubeMX.executablePath" =
                  "/etc/profiles/per-user/sam/bin/stm32cubemx";
                "stm32cube-ide-core.enableTelemetry" = false;
                "editor.formatOnSave" = true;
              };
            };
          };
        };
      };
    };
}
