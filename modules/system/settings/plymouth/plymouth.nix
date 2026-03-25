{
  pkgs,
  ...
}:
{
  flake.modules.nixos.plymouth =
    { pkgs, ... }:
    {
      boot = {
        # Ensure framebuffer console stays at high resolution
        consoleLogLevel = 3; # Reduce kernel messages that might affect display
        # Set framebuffer resolution for boot process
        kernelParams = [
          "video=1920x1080@60"
          "quiet"
          "udev.log_level=3"
          "systemd_show_status=auto"
        ];
        plymouth = {
          enable = true;
          theme = "cybernetic";
          themePackages = with pkgs; [
            # By default we would install all themes
            (adi1090x-plymouth-themes.override {
              selected_themes = [ "cybernetic" ];
            })
          ];
        };
      };
    };
}
