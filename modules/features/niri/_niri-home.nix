{ config, lib, ... }:
{
  wayland.windowManager.niri = {
    enable = true;
    # Kept non-null (same pkgs.niri the NixOS half installs) so checkConfig
    # can validate config.kdl at build time. Portals come from NixOS.
    portalPackage = null;
    # Start from upstream's default config.kdl; `settings` and `extraConfig`
    # are appended after it. See the option description for the attrset ->
    # KDL mapping and https://niri-wm.github.io/niri/Configuration%3A-Introduction.html.
    enableDefaultConfig = true;

    settings = {
      input.keyboard.xkb.layout = "us";
    };

    # Started from the compositor rather than as a graphical-session.target
    # unit, so it doesn't also launch inside Plasma.
    extraConfig = lib.mkIf config.my.features.noctalia ''
      spawn-at-startup "noctalia"
    '';
  };
}
