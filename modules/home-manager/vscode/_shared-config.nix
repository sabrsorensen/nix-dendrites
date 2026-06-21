{
  inventory ? { },
  lib,
  pkgs,
  themeSettings,
  vscodePackage,
}:
let
  remotePlatformSettings = lib.mapAttrs' (
    name: peer: lib.nameValuePair name (if peer ? platform then peer.platform else "linux")
  ) (lib.filterAttrs (_: peer: peer ? ssh && peer.ssh ? base) inventory);

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

  nixExts = [
    "jeff-hykin.better-nix-syntax"
    "LiemLB.nix-flakes"
  ];

  defaultExts = [
    "docker.docker"
    "github.vscode-github-actions"
    "humao.rest-client"
    "ms-azuretools.vscode-containers"
    "redhat.vscode-yaml"
    "tomoki1207.pdf"
  ]
  ++ uiExts
  ++ nixExts
  ++ remoteExts;

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
      "sabrsorensen.party-owl-84"."supported" = true;
      "vscodevim.vim"."supported" = true;
    };
    "remote.SSH.experimental.chat" = false;
    "remote.SSH.remotePlatform" = remotePlatformSettings;
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
    "chat.disableAIFeatures" = true;
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
    "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";
    "[json]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[jsonc]"."editor.defaultFormatter" = "vscode.json-language-features";
    "[nix]" = {
      "editor.tabSize" = 2;
      "editor.indentSize" = "tabSize";
    };
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
      "other" = "inline";
      "comments" = false;
      "strings" = false;
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
    "workbench.editor.highlightModifiedTabs" = true;
    "workbench.editor.revealIfOpen" = true;
  }
  // themeSettings
  // copilotSettings;

  windowsTerminalSettings = {
    "terminal.integrated.defaultProfile.windows" = "NixOS (WSL)";
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
  };

  mkExtensions = exts: pkgs.nix4vscode.forVscodeVersion vscodePackage.version exts;
in
{
  inherit
    defaultExts
    defaultKeyBindings
    defaultProfileOnlySettings
    defaultUserSettings
    mkExtensions
    windowsTerminalSettings
    ;
}
