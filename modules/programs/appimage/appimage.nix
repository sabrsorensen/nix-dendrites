{
  flake.modules.nixos.appimage =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.gui {
      # Run .AppImage files directly
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
}
