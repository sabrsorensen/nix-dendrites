{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-lookup";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "xXJSONDeruloXx";
    repo = "Decky-Lookup";
    rev = "main";
    sha256 = "sha256-Z2dvdxuo98q4FwatEJ/fs5Wwdq9zSrUt/g5vPgW/k44=";
  };

  hash = "sha256-8fqu4t5oy2Y23cU1vhz9vnw8H2m7TCH+yLsz5GzXh/E=";
  buildMessage = "Building Lookup frontend...";
  verifyMainPy = false;
  executablePaths = [ "*/bin/*" ];

  meta = with lib; {
    description = "Game lookup and information tool for Steam Deck";
    homepage = "https://github.com/xXJSONDeruloXx/Decky-Lookup";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
