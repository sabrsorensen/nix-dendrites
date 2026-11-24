{
  # Hyprland's default `scale = "auto"` picks 1.5 for this 1920x1080 panel
  # (logical 1280x720), so everything looks oversized and low-res. Match
  # Plasma's scale 1.
  monitor = {
    output = "eDP-1";
    mode = "preferred";
    position = "auto";
    scale = 1;
  };
}
