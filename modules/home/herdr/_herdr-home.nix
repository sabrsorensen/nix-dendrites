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
    settings.terminal = lib.optionalAttrs config.programs.fish.enable {
      default_shell = lib.getExe pkgs.fish;
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
