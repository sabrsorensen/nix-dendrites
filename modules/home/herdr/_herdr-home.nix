{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  herdrConfig = "${config.xdg.configHome}/herdr/config.toml";
  plugins = import ./_herdr-plugins.nix { inherit pkgs; };
  # herdr-nix's `herdr` is the desktop app (the TUI is `herdr-tui`). Its
  # static libghostty-vt bundles Zig 0.16's compiler_rt, whose objects no
  # linker accepts (ld.bfd: ".eh_frame_hdr refers to overlapping FDEs";
  # lld: undefined empty-named symbol from compiler_rt's cos table). Rust's
  # compiler_builtins and libgcc already provide those symbols, so don't
  # bundle it.
  herdrApp = inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system}.herdr.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace vendor/ghostty/src/build/GhosttyLibVt.zig \
        --replace-fail "lib.bundle_compiler_rt = true;" "lib.bundle_compiler_rt = false;"
    '';
  });
in
{
  home.packages = lib.optional config.my.herdr.app.enable herdrApp;
  warnings = lib.optional config.my.herdr.app.enable ''
    herdr-app is built with libghostty-vt's bundled Zig compiler_rt disabled
    (its objects fail to link: ".eh_frame_hdr refers to overlapping FDEs").
    Drop the overrideAttrs in modules/home/herdr/_herdr-home.nix once
    herdr-app links unpatched -- check with:
      nix build --no-link github:kevinpita/herdr-nix#herdr --override-input nixpkgs "$(nix eval --raw .#nixosConfigurations.kamino.pkgs.path)"
  '';

  programs.herdr = {
    enable = true;
    package = inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system}.herdr-tui;
    plugins = {
      "auto-title".source = plugins.autoTitle;
      spreader = {
        source = plugins.spreader;
        # Every tab needs at least one pane: spreader treats validation
        # *warnings* (e.g. "tab has no panes") as fatal and `apply` exits 1
        # without touching the workspace. `{}` is a plain shell pane.
        configFiles."config.yaml".text = ''
          workspaces:
            - name: nix-dendrites
              root: ~/src/nix-dendrites
              tabs:
                - label: Agent
                  panes:
                    - {}
                - label: Local
                  panes:
                    - {}
                - label: AtlasUponRaiden
                  panes:
                    - {}
                - label: Naboo
                  panes:
                    - {}
                - label: Nevarro
                  panes:
                    - {}
                - label: EmeraldEcho
                  panes:
                    - {}
        '';
      };
    };
    # Herdr falls back to $SHELL, then /bin/sh, for the panes it spawns.
    # Every managed user has Fish enabled (see home/home/_home.nix), so point
    # Herdr at it directly instead of relying on $SHELL/login-shell setup.
    settings = {
      onboarding = false;
      # Party Owl '84 — derive the base palette from the enclosing terminal
      # (Windows Terminal on WSL), then align Herdr's chrome with it. Herdr's
      # `terminal` is a built-in backend name; custom names are not supported.
      theme = {
        name = "terminal";
        auto_switch = false;
        custom = {
          sidebar_bg = "#011627";
          panel_bg = "reset";
          active_row_bg = "#1D3B53";
          selection_bg = "#1B90DD";
          surface0 = "#102A3D";
          accent = "#82AAFF";
          text = "#CCCCCC";
          subtext0 = "#969696";
          mauve = "#C792EA";
          blue = "#82AAFF";
          teal = "#21C7A8";
          green = "#22DA6E";
          yellow = "#C5E478";
          red = "#EF5350";
          surface_dim = "#001122"; # sideBar.background
          surface1 = "#234D70"; # list.activeSelectionBackground
          overlay0 = "#4B6479"; # editorLineNumber.foreground
          overlay1 = "#5F7E97"; # badge.background
          peach = "#F78C6C"; # constant/numeric token orange used throughout
        };
      };
      keys = {
        prefix = "ctrl+b";
        #goto = "prefix+g";
        new_workspace = "prefix+shift+n";
        new_tab = "prefix+t";
        next_tab = "prefix+n";
        previous_tab = "prefix+p";
        #focus_pane_left = "prefix+h"
        #navigate_workspace_down = "j"
        #navigate_pane_down = "ctrl+j"
        split_horizontal = "prefix+minus";
        split_vertical = "prefix+|";
        zoom = "prefix+z";

      };
      ui = {
        accent = "#82AAFF";
        status_indicators = "symbols";
        toast.delivery = "system";
        tab_bar_right = [
          { type = "zoom"; }
          { type = "hostname"; }
          {
            type = "datetime";
            format = "%H:%M";
          }
          #{
          #  type = "text";
          #  text = "prod";
          #}
          #{
          #  type = "command";
          #  command = "~/.config/herdr/status.sh";
          #  interval_seconds = 5;
          #  timeout_seconds = 2;
          #}
        ];
        tab_bar_right_separator = " · ";
      };
      terminal = lib.optionalAttrs config.programs.fish.enable {
        default_shell = lib.getExe pkgs.fish;
      };
    };
  };

  # Home Manager normally links config.toml from the Nix store (read-only).
  # Herdr writes runtime state into it directly -- onboarding completion,
  # UI state, etc. -- which fails with EROFS against a store symlink. Mirror
  # the Codex integration bridge (see
  # modules/platforms/wsl/wsl-work-home/codex/_codex.nix): turn the symlink
  # into a mutable copy once each generation has linked, so Herdr can write
  # to it and you can try out settings at runtime -- the next switch resets
  # it back to what's declared above.
  home.activation.herdrPrepareConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -f ${lib.escapeShellArg herdrConfig} ] && [ ! -L ${lib.escapeShellArg herdrConfig} ]; then
      run mv -f ${lib.escapeShellArg herdrConfig} ${lib.escapeShellArg "${herdrConfig}.herdr-previous"}
    fi
  '';
  home.activation.herdrMutableConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -L ${lib.escapeShellArg herdrConfig} ]; then
      run cp --remove-destination "$(readlink -f ${lib.escapeShellArg herdrConfig})" ${lib.escapeShellArg herdrConfig}
      # cp carries over the Nix store source's mode bits; force the copy
      # writable rather than relying on the source happening to allow it.
      run chmod u+w ${lib.escapeShellArg herdrConfig}
    fi
  '';
}
