# Zed port of the VSCodium profile (../vscode/_vscode-settings.nix) and the
# Vim config (../vim/_vim.nix): Party Owl '84 theme, vim mode with the same
# jj/0/F5 bindings, CaskaydiaCove, fish terminal, and the Nix/Python tooling.
{ pkgs, ... }:
let
  themeName = "Party Owl '84";
  font = "CaskaydiaCove Nerd Font Mono";
in
{
  programs.zed-editor = {
    enable = true;
    enableMcpIntegration = true;
    extensions = [
      "docker-compose"
      "dockerfile"
      "fish"
      "github-actions"
      "nix"
      "toml"
    ];
    extraPackages = with pkgs; [
      nixd
      nixfmt
    ];
    themes.party-owl-84 = import ./_party-owl-84-theme.nix;

    userKeymaps = [
      {
        # workbench.action.nextEditor / previousEditor
        context = "Workspace";
        bindings = {
          "shift-right" = "pane::ActivateNextItem";
          "shift-left" = "pane::ActivatePreviousItem";
        };
      }
      {
        # Editor binds shift-arrows to selection; keep tab cycling in normal mode.
        context = "Editor && vim_mode == normal";
        bindings = {
          "shift-right" = "pane::ActivateNextItem";
          "shift-left" = "pane::ActivatePreviousItem";
        };
      }
      {
        # imap jj <ESC>
        context = "vim_mode == insert";
        bindings."j j" = "vim::NormalBefore";
      }
      {
        # map 0 ^ (excluding a pending count, where 0 is a digit)
        context = "VimControl && !menu && !VimCount";
        bindings."0" = "vim::FirstNonWhitespace";
      }
      {
        # nnoremap <F5> :set nonumber!<CR>
        context = "Editor";
        bindings."f5" = "editor::ToggleLineNumbers";
      }
    ];

    userSettings = {
      theme = {
        mode = "dark";
        dark = themeName;
        light = themeName;
      };
      # Port of nixThemeTokenColorCustomizations. Zed overrides are per theme,
      # not per language; variable.member is effectively Nix-only (attr keys).
      theme_overrides.${themeName}.syntax = {
        "variable.member" = {
          color = "#c5e478";
          font_style = "italic";
        };
        "variable.parameter" = {
          color = "#c5e478";
          font_style = "italic";
        };
        "punctuation.special".color = "#ec5f67";
        "variable.special".color = "#8eace3";
      };

      buffer_font_family = font;
      buffer_font_features.calt = true;
      colorize_brackets = true;
      edit_predictions.provider = "none";
      file_scan_exclusions = [
        # Zed defaults (setting this replaces them).
        "**/.git"
        "**/.svn"
        "**/.hg"
        "**/.jj"
        "**/.sl"
        "**/.repo"
        "**/CVS"
        "**/.DS_Store"
        "**/Thumbs.db"
        "**/.classpath"
        "**/.settings"
        # files.exclude
        "**/.vs"
        "**/TestResults"
        "**/bin"
        "**/obj"
      ];
      horizontal_scroll_margin = 10;
      indent_guides.coloring = "indent_aware";
      restore_on_startup = "none";
      show_whitespaces = "boundary";
      tab_size = 2;
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      terminal = {
        blinking = "on";
        copy_on_select = true;
        font_family = font;
        font_features.calt = true;
        shell.program = "fish";
      };
      use_smartcase_search = true;
      vertical_scroll_margin = 10;
      vim_mode = true;
      vim = {
        use_smartcase_find = true;
        use_system_clipboard = "never";
      };

      languages.Nix = {
        formatter.external.command = "nixfmt";
        language_servers = [
          "nixd"
          "!nil"
        ];
      };
      lsp.basedpyright.settings."basedpyright.analysis" = {
        autoImportCompletions = true;
        autoSearchPaths = true;
        diagnosticSeverityOverrides = {
          reportMissingParameterType = "warning";
          reportUnknownArgumentType = "warning";
          reportUnknownMemberType = "warning";
          reportUnknownParameterType = "warning";
          reportUnknownVariableType = "warning";
        };
        typeCheckingMode = "strict";
        useLibraryCodeForTypes = true;
      };
    };
  };
}
