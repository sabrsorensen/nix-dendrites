{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-autoflatpaks";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "jurassicplayer";
    repo = "decky-autoflatpaks";
    rev = "main";
    sha256 = "sha256-CjVjHAjTGMP5ATo+7lDwOZ0OI0SvjkqVYUd0xHjfLbA=";
  };

  hash = "sha256-xZChs8C6+CVAcU6vaPnOpQa3m91YiDp8doxTKAuZc98=";
  buildMessage = "Building AutoFlatpaks frontend...";

  meta = with lib; {
    description = "Automatically clean up and manage Flatpaks on Steam Deck";
    homepage = "https://github.com/jurassicplayer/decky-autoflatpaks";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
