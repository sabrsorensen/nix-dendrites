{
  flake.modules.nixos.appimage = {
    # Run .AppImage files directly
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
