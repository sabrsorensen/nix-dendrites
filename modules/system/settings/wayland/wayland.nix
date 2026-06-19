{
  flake.modules.nixos.wayland =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.gui {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
    };
}
