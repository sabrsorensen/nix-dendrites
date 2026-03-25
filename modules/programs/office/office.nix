{
  flake.modules.homeManager.office =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    lib.mkMerge [
      {
        # settings for all systems
        home.packages = with pkgs; [
        ];
      }
      (lib.mkIf (pkgs.stdenv.isLinux) {
        # NixOS settings
        home.packages = with pkgs; [
          hunspell
          hunspellDicts.en_US
          libreoffice-qt6
          gimp3-with-plugins
        ];
      })
    ];
}
