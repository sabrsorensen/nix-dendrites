{ ... }:
{
  flake.modules.nixos.desktop =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.desktop = lib.mkEnableOption "generic desktop session";
      config = lib.mkIf config.my.host.features.desktop (import ./_desktop.nix args);
    };
}
