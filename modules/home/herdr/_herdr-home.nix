{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
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
}
