{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  appimageTools,
  appimage-run,
}:
let
  # NMSE bundles its own Wine build; that Wine's ntdll.so is linked against
  # libunwind.so.8, which appimage-run's default FHS env doesn't provide (see
  # also modules/features/appimage/_appimage.nix, which fixes this generally
  # for programs.appimage). Fixed here too so `nmse` works standalone even on
  # a host that doesn't enable my.host.features.appimage.
  appimageRun = appimage-run.override {
    extraPkgs = pkgs: [ pkgs.libunwind ];
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nmse";
  version = "1.3.16";

  # Upstream only ships prebuilt releases (AppImage / macOS dmg), no source
  # build. The asset filename embeds the version, so `/latest/download/`
  # resolves today but will 404 once a newer release replaces this exact
  # filename -- that failure is the signal to bump `version` and `hash`
  # together (the URL never silently drifts to different content, since
  # fetchurl still enforces the pinned hash).
  src = fetchurl {
    url = "https://github.com/vectorcmdr/NMSE/releases/latest/download/NMSE-${finalAttrs.version}-Release-x64.AppImage";
    hash = "sha256-vP2eSevVI5qynM0KDnrFbIw6QGBmh50ANK9P+3/Ol8Y=";
  };

  # Only needed to pull nmse.png out for the desktop icon; the AppImage
  # itself is run as-is (unextracted) through appimage-run below.
  appdir = appimageTools.extract {
    inherit (finalAttrs) pname version src;
  };

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "nmse";
      desktopName = "NMSE";
      comment = "No Man's Sky Save Editor";
      exec = "nmse";
      icon = "nmse";
      categories = [
        "Game"
        "Utility"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/libexec/nmse.AppImage"
    install -Dm444 "$appdir/nmse.png" "$out/share/icons/hicolor/256x256/apps/nmse.png"

    makeWrapper ${lib.getExe appimageRun} "$out/bin/nmse" \
      --add-flags "$out/libexec/nmse.AppImage"

    runHook postInstall
  '';

  meta = {
    description = "No Man's Sky Save Editor (NMSE)";
    homepage = "https://github.com/vectorcmdr/NMSE";
    license = lib.licenses.agpl3Only;
    mainProgram = "nmse";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
