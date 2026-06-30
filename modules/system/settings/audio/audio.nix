{
  flake.modules.nixos.audio =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.gui {
      # Enable sound with pipewire.
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        #jack.enable = true;
      };
    };
}
