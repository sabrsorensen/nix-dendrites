{ pkgs }:
{
  # Run .AppImage files directly
  programs.appimage = {
    enable = true;
    binfmt = true;
    # AppImages that bundle their own Wine (e.g. NMSE) ship an ntdll.so linked
    # against libunwind.so.8, which appimage-run's FHS env doesn't provide.
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [ pkgs.libunwind ];
    };
  };
}
