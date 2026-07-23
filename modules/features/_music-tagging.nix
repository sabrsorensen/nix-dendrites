{ inputs, ... }:
{
  flake.modules.nixos.music-tagging =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mediaConsumer =
        config.my.host.services.airsonic || config.my.host.services.gonic || config.my.host.services.plex;
      package = inputs.demlo.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    # Atlas's predecessor imported the NixOS Demlo module, but not the
    # separate Beets/Demlo Home Manager modules.  Keep the active behavior
    # exact: media consumers receive the Demlo command system-wide, without
    # adding an otherwise unused Beets/Python audio-processing closure.
    lib.mkIf mediaConsumer {
      environment.systemPackages = [ package ];
    };
}
