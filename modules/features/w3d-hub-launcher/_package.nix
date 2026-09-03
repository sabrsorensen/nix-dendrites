{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  unzip,
  copyDesktopItems,
  makeDesktopItem,
  # W3D Hub games are Windows titles the launcher runs through Wine; it also
  # shells out to `winetricks`, `winecfg` and `which` by bare name. Provided
  # on the wrapper's own PATH so the launcher works regardless of whether the
  # host enables my.host.features.wine (matching that feature's WoW64 build).
  wineWow64Packages,
  winetricks,
  which,
  # Runtime libraries the bundled Gosu / cyberarm_engine native extensions
  # dlopen. The Tebako binary itself only links libc, so none of these appear
  # in DT_NEEDED -- they have to be on LD_LIBRARY_PATH at launch instead. This
  # set mirrors Gosu's documented Linux build dependencies plus the audio
  # codecs libsndfile/gosu load by soname.
  SDL2,
  SDL2_image,
  SDL2_ttf,
  SDL2_mixer,
  libGL,
  libGLU,
  openal,
  libsndfile,
  mpg123,
  libvorbis,
  libogg,
  flac,
  libopus,
  pango,
  cairo,
  glib,
  harfbuzz,
  fontconfig,
  freetype,
  gmp,
  zlib,
  stdenv,
}:
let
  runtimeLibs = [
    SDL2
    SDL2_image
    SDL2_ttf
    SDL2_mixer
    libGL
    libGLU
    openal
    libsndfile
    mpg123
    libvorbis
    libogg
    flac
    libopus
    pango
    cairo
    glib
    harfbuzz
    fontconfig
    freetype
    gmp
    zlib
    stdenv.cc.cc.lib
  ];
  runtimePath = [
    wineWow64Packages.stable
    winetricks
    which
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  # Private package recipe. Hosts opt in through
  # my.host.features.w3dHubLauncher, which also allows this unlicensed binary.
  pname = "w3d-hub-linux-launcher";
  version = "0.9.2";

  src = fetchurl {
    url = "https://github.com/cyberarm/w3d_hub_linux_launcher/releases/download/v${finalAttrs.version}/w3d_hub_linux_launcher-linux-x86_64.zip";
    hash = "sha256-TKMseKZ6Dq3QdGgj1+beEsfqDf5usasZmFDTicq+ZY8=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    unzip
    copyDesktopItems
  ];

  buildInputs = [
    zlib
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  desktopItems = [
    (makeDesktopItem {
      name = "w3d-hub-launcher";
      desktopName = "W3D Hub Launcher";
      comment = "Launcher for W3D Hub games";
      exec = "w3d-hub-launcher";
      icon = "w3d-hub-launcher";
      categories = [
        "Game"
        "Network"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 w3d_hub_linux_launcher \
      "$out/libexec/w3d-hub-launcher/w3d_hub_linux_launcher"

    # The launcher resolves media/ and locales/ relative to its working
    # directory (GAME_ROOT_PATH = Dir.pwd) and writes data/ there too, so the
    # wrapper points it at a per-user runtime directory and links the
    # read-only assets into place.
    mkdir -p "$out/share/w3d-hub-launcher"
    cp -r media locales "$out/share/w3d-hub-launcher/"

    install -Dm644 media/icons/w3dhub.png "$out/share/pixmaps/w3d-hub-launcher.png"

    makeWrapper "$out/libexec/w3d-hub-launcher/w3d_hub_linux_launcher" \
      "$out/bin/w3d-hub-launcher" \
      --prefix PATH : "${lib.makeBinPath runtimePath}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
      --run ${lib.escapeShellArg ''
        w3dhub_runtime="''${XDG_DATA_HOME:-$HOME/.local/share}/w3d-hub-launcher"
        mkdir -p "$w3dhub_runtime/data"
        ln -sfn "@out@/share/w3d-hub-launcher/media" "$w3dhub_runtime/media"
        ln -sfn "@out@/share/w3d-hub-launcher/locales" "$w3dhub_runtime/locales"
        cd "$w3dhub_runtime"
      ''}

    substituteInPlace "$out/bin/w3d-hub-launcher" --replace-fail "@out@" "$out"

    runHook postInstall
  '';

  meta = {
    description = "Linux-friendly launcher for W3D Hub games";
    homepage = "https://github.com/cyberarm/w3d_hub_linux_launcher";
    # Upstream ships no license file; treat the prebuilt binary as unfree.
    license = lib.licenses.unfree;
    mainProgram = "w3d-hub-launcher";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
