{ ... }:
{
  flake.modules.nixos.plymouth =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.plymouth = lib.mkEnableOption "Plymouth boot splash";
      config = lib.mkIf config.my.host.features.plymouth (import ./_plymouth.nix args);
    };
}
