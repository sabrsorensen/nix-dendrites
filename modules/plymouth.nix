{ ... }:
{
  flake.modules.nixos.plymouth =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.gui {
      boot = {
        consoleLogLevel = 3;
        # Pick the highest GOP framebuffer mode before KMS takes over.  The
        # firmware mode kept by systemd-boot is often a low-resolution mode.
        loader.systemd-boot.consoleMode = lib.mkDefault "max";
        kernelParams = [
          "video=1920x1080@60"
          "quiet"
          "udev.log_level=3"
          "systemd_show_status=auto"
        ];
        plymouth = {
          enable = true;
          theme = "cybernetic";
          themePackages = [
            (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "cybernetic" ]; })
          ];
        };
      };
    };
}
