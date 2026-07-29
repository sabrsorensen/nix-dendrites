{ ... }:
{
  flake.modules.nixos.music-tagging =
    {
      config,
      lib,
      ...
    }:
    {
      options.my.musicTagging = {
        beets.enable = lib.mkEnableOption "Beets music-library management";
        demlo.enable = lib.mkEnableOption "Demlo audio-file processing";
      };

      config = lib.mkIf config.my.host.features.musicTagging {
        my.musicTagging = {
          beets.enable = true;
          demlo.enable = true;
        };
      };
    };
}
