{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-tabmaster";
  version = "2.15.0";

  src = fetchFromGitHub {
    owner = "Tormak9970";
    repo = "TabMaster";
    rev = "v2.15.0";
    sha256 = "sha256-Px6/03j1W+25HJP7iOT4Qh4y81gAJvCgeWrCKIudH0Q=";
  };

  hash = "sha256-pA9OCFj4xdtAST7qwmYUI/ZdNhWN0PvYCvYi3H8/mcQ=";
  buildMessage = "Building TabMaster frontend...";
  verifyMainPy = false;

  meta = with lib; {
    description = "Advanced tab management for Steam Deck";
    homepage = "https://github.com/Tormak9970/TabMaster";
    license = licenses.gpl3;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
