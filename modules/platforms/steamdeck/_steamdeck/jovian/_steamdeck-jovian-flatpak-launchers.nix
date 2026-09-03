{
  config,
  lib,
  pkgs,
  ...
}:
let
  guard =
    !builtins.elem "bootstrap" config.my.host.tags && !builtins.elem "installer" config.my.host.tags;

  # Steam's Gaming Mode force-preloads gameoverlayrenderer.so into every
  # shortcut it launches. That library needs libGL.so.1, which is absent
  # from every default dynamic-loader path on NixOS, so the dynamically
  # linked `flatpak` binary aborts at exec and a non-Steam Flatpak shortcut
  # hangs forever on the Steam spinner. Wrappers that route through a shell
  # fail identically (the overlay is preloaded into the shell itself).
  #
  # A statically linked binary has no interpreter, so ld.so never runs and
  # LD_PRELOAD is ignored. This launcher always starts, fixes
  # LD_LIBRARY_PATH so the overlay resolves once `flatpak` re-execs, then
  # hands off to `flatpak run`. See xstreaming-launch.c for the full story.
  #
  # Point the XStreamingDesktop non-Steam shortcut's Target at
  # /run/current-system/sw/bin/xstreaming-launch with empty launch options.
  xstreaming-launch = pkgs.pkgsStatic.stdenv.mkDerivation {
    pname = "xstreaming-launch";
    version = "1";
    src = ./xstreaming-launch.c;
    dontUnpack = true;
    buildPhase = ''
      runHook preBuild
      $CC -O2 -static \
        -DGLVND_LIBDIR='"${pkgs.libglvnd}/lib"' \
        -DFLATPAK_BIN='"/run/current-system/sw/bin/flatpak"' \
        -DFLATPAK_APP_ID='"io.github.Geocld.XStreamingDesktop"' \
        -o xstreaming-launch "$src"
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 xstreaming-launch "$out/bin/xstreaming-launch"
      runHook postInstall
    '';
    meta = {
      description = "Static Gaming Mode launcher for the XStreamingDesktop Flatpak";
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  environment.systemPackages = lib.mkIf guard [ xstreaming-launch ];
}
