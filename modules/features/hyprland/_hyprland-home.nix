{
  config,
  lib,
  pkgs,
  ...
}:
let
  lua = lib.generators.mkLuaInline;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    # The NixOS half (programs.hyprland) installs Hyprland and its portal.
    package = null;
    portalPackage = null;

    # stateVersion >= 26.05 selects the Lua config (hypr/hyprland.lua): each
    # attribute becomes an `hl.<name>(...)` call. See the option description
    # of wayland.windowManager.hyprland.settings and https://wiki.hypr.land.
    settings = {
      terminal._var = "${pkgs.ghostty}/bin/ghostty";
      mod._var = "SUPER";
      filemanager._var = "${pkgs.kdePackages.dolphin}/bin/dolphin";

      config = {
        input = {
          kb_layout = "us";
          kb_variant = "dvorak";
        };
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
        };
      };

      bind = [
        {
          _args = [
            (lua ''mod .. " + RETURN"'')
            (lua ''hl.dsp.exec_cmd("ghostty")'')
          ];
        }
        {
          _args = [
            (lua ''mod .. " + Q"'')
            (lua "hl.dsp.window.close()")
          ];
        }
      ];

      # Started from the compositor rather than as a graphical-session.target
      # unit, so it doesn't also launch inside Plasma.
      on = lib.mkIf config.my.features.noctalia {
        _args = [
          "hyprland.start"
          (lua ''
            function()
              hl.exec_cmd("noctalia")
            end'')
        ];
      };
    };
  };
}
