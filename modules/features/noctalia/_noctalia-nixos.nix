{ config, ... }:
let
  features = config.my.host.features;
in
{
  assertions = [
    {
      # Noctalia is launched by the compositor (see the hyprland/niri home
      # payloads); without one it is installed but never started.
      assertion = features.hyprland || features.niri;
      message = "my.host.features.noctalia needs a compositor that starts it: enable features.hyprland or features.niri.";
    }
  ];

  # System services the shell's widgets read over D-Bus (battery, power
  # profiles). Plasma enables these too; they are harmless without it.
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
}
