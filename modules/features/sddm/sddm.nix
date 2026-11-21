{ ... }:
{
  flake.modules.nixos.sddm =
    args@{ config, lib, ... }:
    {
      options.my.host.features.sddm = lib.mkEnableOption "the SDDM display manager";
      config = lib.mkIf config.my.host.features.sddm (import ./_sddm.nix args);
    };
}
