{ ... }:
{
  flake.modules.nixos.bootstrap-enroll =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      enabled = builtins.elem "bootstrap" config.my.host.tags;
    in
    lib.mkIf enabled (import ./_content.nix args);
}
