{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-brightness-bar";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "rasitayaz";
    repo = "decky-brightness-bar";
    rev = "main";
    sha256 = "sha256-pUA81PmMfNIu0184rSxw1LPw4HldzIJAFfmf/LyfiBQ=";
  };

  hash = "sha256-rHoJpFwYFokFb/kU/WOk7/o3vhbnn1sWRj5EPwV9V1Y=";
  buildMessage = "Building Brightness Bar frontend...";

  meta = with lib; {
    description = "Customizable brightness bar for Steam Deck";
    homepage = "https://github.com/rasitayaz/decky-brightness-bar";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
