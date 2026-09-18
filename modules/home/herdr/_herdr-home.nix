{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  herdrConfig = "${config.xdg.configHome}/herdr/config.toml";
in
{
  programs.herdr = {
    enable = true;
    package = inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
    # Herdr falls back to $SHELL, then /bin/sh, for the panes it spawns.
    # Every managed user has Fish enabled (see home/home/_home.nix), so point
    # Herdr at it directly instead of relying on $SHELL/login-shell setup.
    settings = {
      # Party Owl '84 — derive the base palette from the enclosing terminal
      # (Windows Terminal on WSL), then align Herdr's chrome with it. Herdr's
      # `terminal` is a built-in backend name; custom names are not supported.
      theme = {
        name = "terminal";
        custom = {
          sidebar_bg = "#011627";
          panel_bg = "reset";
          active_row_bg = "#1D3B53";
          selection_bg = "#1B90DD";
          accent = "#82AAFF";
          text = "#CCCCCC";
          subtext0 = "#969696";
          mauve = "#C792EA";
          blue = "#82AAFF";
          teal = "#21C7A8";
          green = "#22DA6E";
          yellow = "#C5E478";
          red = "#EF5350";
        };
      };
      ui = {
        accent = "#82AAFF";
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
