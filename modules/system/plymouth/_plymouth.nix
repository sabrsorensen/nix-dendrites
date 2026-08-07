{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot = {
    # Ensure framebuffer console stays at high resolution
    consoleLogLevel = 3; # Reduce kernel messages that might affect display
    loader.systemd-boot.consoleMode = lib.mkDefault "max";
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "systemd.show_status=auto"
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
}
