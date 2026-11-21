{ ... }:
{
  programs.noctalia = {
    enable = true;
    # Not a graphical-session.target unit: that would also start it inside
    # Plasma. The hyprland and niri payloads spawn it instead.
    systemd.enable = false;
    # Written as TOML; runtime changes from the settings menu still win.
    # See https://docs.noctalia.dev/noctalia/configuration/.
    settings = { };
  };
}
