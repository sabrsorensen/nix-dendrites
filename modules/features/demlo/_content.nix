{ inputs, ... }:
{
  flake.modules.nixos.demlo =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.my.host.home.username;
    in
    lib.mkMerge [
      (lib.mkIf config.my.host.features.demlo {
        environment.systemPackages = [
          inputs.demlo.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      })
      (lib.mkIf (config.my.host.features.demlo && config.my.host.home.enable) {
        home-manager.users.${username}.xdg.configFile = {
          "demlo/config.lua".source = ./assets/config.lua;
          "demlo/scripts/10-tag-normalize.lua".source = ./assets/scripts/10-tag-normalize.lua;
          "demlo/scripts/30-tag-case.lua".source = ./assets/scripts/30-tag-case.lua;
          "demlo/scripts/60-path.lua".source = ./assets/scripts/60-path.lua;
          "demlo/scripts/70-cover.lua".source = ./assets/scripts/70-cover.lua;
        };
      })
    ];
}
