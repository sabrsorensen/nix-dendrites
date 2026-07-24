{ inputs, ... }:
{
  flake.modules.nixos.demlo =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.musicTagging.demlo.enable {
      environment.systemPackages = [
        inputs.demlo.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      home-manager.users.sam.xdg.configFile = {
        "demlo/config.lua".source = ./demlo/config.lua;
        "demlo/scripts/10-tag-normalize.lua".source = ./demlo/scripts/10-tag-normalize.lua;
        "demlo/scripts/30-tag-case.lua".source = ./demlo/scripts/30-tag-case.lua;
        "demlo/scripts/60-path.lua".source = ./demlo/scripts/60-path.lua;
        "demlo/scripts/70-cover.lua".source = ./demlo/scripts/70-cover.lua;
      };
    };
}
