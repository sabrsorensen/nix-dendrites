{ ... }:
{
  flake.modules.nixos.office =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.features.office && config.my.host.home.enable) {
      home-manager.users.sam.home.packages = [
        pkgs.hunspell
        pkgs.hunspellDicts.en_US
        #pkgs.libreoffice-qt6
        pkgs.gimp3-with-plugins
      ];
    };
}
