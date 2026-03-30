{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-protondb";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "bschelst";
    repo = "protondb-decky";
    rev = "main";
    sha256 = "sha256-MUPcMNHJU6hQMl4r4G3N79AUO2npLI2NZaTJGqIbbQk=";
  };

  hash = "sha256-WJlCk355suOqpHyEse23uglk0XTB33D53CHmOyTS6v0=";
  buildMessage = "Building ProtonDB frontend...";
  executablePaths = [ "*/bin/*" ];

  meta = with lib; {
    description = "ProtonDB badges and compatibility ratings for Steam Deck";
    homepage = "https://github.com/bschelst/protondb-decky";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
