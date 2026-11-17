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
      "csharp"
      "csv"
      "docker-compose"
      "dockerfile"
      "fish"
      "github-actions"
      "just"
      "liquid"
      "make"
      "nix"
      "python"
      "python-requirements"
      "rainbow-csv"
      "ssh-config"
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
        context = "Editor && (vim_mode == normal || vim_mode == helix_normal)";
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
        # Helix's space menu, copied from Zed's own helix_mode bindings
        # (assets/keymaps/vim.json) so vim mode uses mnemonic letters instead
        # of chords that are awkward on Dvorak, and the habits carry over to
        # helix_mode. `space p`/`space y` use the system clipboard, which vim
        # mode otherwise doesn't (use_system_clipboard = "never"). Only active
        # with helix_mode off; Helix modes get Zed's built-in copy of this menu.
        context = "(vim_mode == normal || vim_mode == visual) && !menu";
        bindings = {
          "space f" = "file_finder::Toggle";
          "space b" = "tab_switcher::OpenInActivePane";
          "space s" = "outline::Toggle";
          "space shift-s" = "project_symbols::Toggle";
          "space /" = "pane::DeploySearch";
          "space k" = "editor::Hover";
          "space d" = "editor::GoToDiagnostic";
          "space r" = "editor::Rename";
          "space a" = "editor::ToggleCodeActions";
          "space h" = "editor::SelectAllMatches";
          "space c" = [
            "editor::ToggleComments"
            {
              advance_downwards = false;
              comment_empty_lines = false;
            }
          ];
          "space p" = "editor::Paste";
          "space y" = "editor::Copy";
          "space w v" = "pane::SplitRight";
          "space w s" = "pane::SplitDown";
          "space w h" = "workspace::ActivatePaneLeft";
          "space w j" = "workspace::ActivatePaneDown";
          "space w k" = "workspace::ActivatePaneUp";
          "space w l" = "workspace::ActivatePaneRight";
          "space w q" = "pane::CloseActiveItem";
        };
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

      agent = {
        dock = "right";
        threads_sidebar = {
          auto_open = false;
        };
      };
      agent_servers.claude-acp.type = "registry";
      base_keymap = "Zed";
      # Projects opened from the UI/OS and from `zed <path>` both get a new window.
      default_open_behavior = "new_window";
      cli_default_open_behavior = "new_window";
      reveal_if_open = true;
      # Load a project's direnv/nix-direnv environment (e.g. a flake devShell)
      # for language servers, tasks and the terminal by running
      # `direnv export json` directly, independent of shell startup files.
      load_direnv = "direct";
      session.trust_all_worktrees = true;
      collaboration_panel.dock = "left";
      git_panel.dock = "left";
      outline_panel.dock = "left";

      buffer_font_family = font;
      buffer_font_features.calt = true;
      buffer_font_size = 15;
      colorize_brackets = true;
      cursor_animation.enabled = true;
      disable_ai = true;
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
      format_on_save = "on";
      git.inline_blame.enabled = true;
      horizontal_scroll_margin = 10;
      indent_guides.coloring = "indent_aware";
      minimap.show = "always";
      project_panel = {
        bold_folder_labels = true;
        diagnostic_badges = true;
        dock = "left";
        git_status_indicator = true;
      };
      restore_on_startup = "launchpad";
      show_whitespaces = "boundary";
      status_bar.line_endings_button = true;
      tabs.file_icons = true;
      tab_size = 2;
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      terminal = {
        bell = "system";
        blinking = "on";
        copy_on_select = true;
        font_family = font;
        font_features.calt = true;
        shell.program = "fish";
      };
      title_bar = {
        button_layout = "platform_default";
        show_menus = false;
      };
      ui_font_size = 16;
      use_smartcase_search = true;
      vertical_scroll_margin = 10;
      vim_mode = true;
      # Select-then-act editing (Helix keys) on top of vim mode; insert-mode
      # bindings like `jj` and the vim.* settings below still apply.
      helix_mode = true;
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
