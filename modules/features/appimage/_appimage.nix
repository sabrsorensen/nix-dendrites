{ pkgs }:
{
  # Run .AppImage files directly
  programs.appimage = {
    enable = true;
    binfmt = true;
    # appimage-run's FHS env is missing libraries some AppImages expect:
    # - libunwind: AppImages that bundle their own Wine (e.g. NMSE) ship an
    #   ntdll.so linked against libunwind.so.8.
    # - icu: AppImages that bundle a .NET runtime (e.g. Pokopia Native
    #   Builder) abort with "Couldn't find a valid ICU package" without it.
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [
        pkgs.libunwind
        pkgs.icu
      ];
    };
  };
  warnings = [
    ''
      programs.appimage.package is appimage-run overridden with libunwind and
      icu in its FHS env (bundled-Wine AppImages such as NMSE link ntdll.so
      against libunwind.so.8; bundled-.NET AppImages such as Pokopia Native
      Builder need libicu). Remove each from the override in
      modules/features/appimage/_appimage.nix once nixpkgs ships it in
      appimage-run itself -- check with:
        grep -nE 'libunwind|icu' "$(nix eval --raw .#nixosConfigurations.kamino.pkgs.path)"/pkgs/build-support/appimage/default.nix
    ''
  ];
}
