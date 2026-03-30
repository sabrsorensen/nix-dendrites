{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-kdeconnect";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "safijari";
    repo = "Decky-KDE-Connect";
    rev = "main";
    sha256 = "sha256-hX2VOy1Q90umizQ3WXuSLRfR49ZOnIQ+/xCIaAZcWuI=";
  };

  hash = "sha256-fqNiU22sjdOArkYQkWnQGR819HU+xpXFt5fPS9qrwic=";
  buildMessage = "Building KDE Connect frontend...";
  executablePaths = [ "*/bin/*" ];

  meta = with lib; {
    description = "KDE Connect integration for Steam Deck";
    homepage = "https://github.com/safijari/Decky-KDE-Connect";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
