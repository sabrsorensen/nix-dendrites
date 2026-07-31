{ ... }:
{
  # The private work input supplies the SOPS secret declarations.  This module
  # owns only the portable WSL work tooling and is safe on every other host.
  flake.modules.nixos.wsl-work-home =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.platform == "wsl" && config.my.host.home.enable) (
      import ./_content.nix args
    );
}
