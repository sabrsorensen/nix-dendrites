{ ... }:
{
  flake.modules.nixos.demlo-home =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.musicTagging {
      # The command itself is supplied system-wide by the media-consumer
      # module. This Home Manager module owns only its user configuration.
      home-manager.users.sam.xdg.configFile = {
        "demlo/config.lua".source = ./demlo/config.lua;
        "demlo/scripts/10-tag-normalize.lua".source = ./demlo/scripts/10-tag-normalize.lua;
        "demlo/scripts/30-tag-case.lua".source = ./demlo/scripts/30-tag-case.lua;
        "demlo/scripts/60-path.lua".source = ./demlo/scripts/60-path.lua;
        "demlo/scripts/70-cover.lua".source = ./demlo/scripts/70-cover.lua;
      };
    };
}
