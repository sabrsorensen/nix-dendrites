{ ... }:
{
  flake.modules.nixos.audio =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.gui {
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
      };
    };
}
