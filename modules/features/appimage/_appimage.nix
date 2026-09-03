{ }:
{
  # Run .AppImage files directly
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
