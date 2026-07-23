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
      defaultExtensions = mkExtensions [
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
      ];
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
      home-manager.users.sam.programs.vscodium = {
        enable = true;
        package = themePackage;
        profiles.default = {
          enableExtensionUpdateCheck = true;
          enableUpdateCheck = true;
          extensions = defaultExtensions;
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
            userSettings = defaultSettings // {
              "[python]"."editor.formatOnType" = true;
              "python.analysis.typeCheckingMode" = "strict";
              "editor.formatOnSave" = true;
            };
          };
          STM32 = {
            extensions = defaultExtensions ++ stm32Extensions;
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
}
