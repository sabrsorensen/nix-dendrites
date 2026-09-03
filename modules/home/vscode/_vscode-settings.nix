{ vscodeTheme, ... }:
let
  nixThemeTokenColorCustomizations = themeName: {
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
    .${vscodeTheme};
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
    "claudeCode.preferredLocation" = "panel";
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
  defaultProfileUserSettings = defaultSettings // {
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
  mkHigiUserSettings =
    {
      runCodexInWsl ? false,
    }:
    defaultSettings
    // {
      "extensions.verifySignature" = false;
      "snyk.advanced.cliPath" = "C:\\Users\\ssorensen\\AppData\\Local\\snyk\\vscode-cli\\snyk-win.exe";
      "snyk.securityAtInception.autoConfigureSnykMcpServer" = true;
      "snyk.securityAtInception.executionFrequency" = "On Code Generation";
    }
    // (
      if runCodexInWsl then
        {
          "chatgpt.runCodexInWindowsSubsystemForLinux" = true;
        }
      else
        { }
    );
  nixProfileUserSettings = defaultSettings // {
    "[nix]" = {
      "editor.tabSize" = 2;
      "editor.indentSize" = "tabSize";
    };
    "[python]"."editor.formatOnType" = true;
    "editor.formatOnSave" = true;
  };
  pythonProfileUserSettings = defaultSettings // {
    "[python]"."editor.formatOnType" = true;
    "python.analysis.typeCheckingMode" = "strict";
    "editor.formatOnSave" = true;
  };
  stm32ProfileUserSettings = defaultSettings // {
    "stm32cube-ide-core.configuration.productSTM32CubeMX.executablePath" =
      "/etc/profiles/per-user/sam/bin/stm32cubemx";
    "stm32cube-ide-core.enableTelemetry" = false;
    "editor.formatOnSave" = true;
  };
  nixProfileSnippets = {
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
in
{
  inherit
    defaultKeybindings
    defaultProfileUserSettings
    defaultSettings
    mkHigiUserSettings
    nixProfileSnippets
    nixProfileUserSettings
    pythonProfileUserSettings
    stm32ProfileUserSettings
    ;
}
