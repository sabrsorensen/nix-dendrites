{
  lib,
  stdenv,
  cmake,
  pkg-config,
  qt6,
  ffmpeg,
  curl,
  libsecret,
  reolink-native-linux-src,
  ...
}:
let
  # Upstream's git tags lag its releases, so the version is read from the
  # project() call in the pinned CMakeLists.txt instead.
  version =
    let
      match = builtins.match ".*project\\(reolink-client[[:space:]]+VERSION[[:space:]]+([0-9.]+).*" (
        lib.readFile "${reolink-native-linux-src}/CMakeLists.txt"
      );
    in
    if match == null then
      throw "reolink-native-linux: no project VERSION in CMakeLists.txt"
    else
      lib.head match;
in
stdenv.mkDerivation {
  pname = "reolink-native-linux";
  inherit version;

  src = reolink-native-linux-src;

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
    qt6.qttools
    qt6.qtshadertools
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtmultimedia
    qt6.qtshadertools
    qt6.qtwayland
    ffmpeg
    curl
    libsecret
  ];

  cmakeFlags = [ (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release") ];

  meta = {
    description = "Native Qt6 desktop client for Reolink cameras and NVRs";
    homepage = "https://github.com/TodesengelX/reolink-native-linux";
    license = lib.licenses.mit;
    mainProgram = "reolink-client";
    platforms = lib.platforms.linux;
  };
}
