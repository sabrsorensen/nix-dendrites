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
  warnings = [
    ''
      programs.appimage.package is appimage-run overridden with libunwind in
      its FHS env (bundled-Wine AppImages such as NMSE link ntdll.so against
      libunwind.so.8). Remove the override in
      modules/features/appimage/_appimage.nix once nixpkgs ships libunwind in
      appimage-run itself -- check with:
        grep -n libunwind "$(nix eval --raw .#nixosConfigurations.kamino.pkgs.path)"/pkgs/build-support/appimage/default.nix
    ''
  ];
}
