{
  flake.modules.nixos.wayland = {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}