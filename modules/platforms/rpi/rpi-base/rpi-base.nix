{ ... }:
{
  flake.modules.nixos.rpi-base =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hasSam = config.my.host.home.enable || builtins.elem "bootstrap" config.my.host.tags;
    in
    lib.mkIf config.my.host.is.rpi (import ./_content.nix (args // { inherit hasSam; }));
}
