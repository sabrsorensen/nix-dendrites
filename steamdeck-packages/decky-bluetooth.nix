{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-bluetooth";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "Outpox";
    repo = "Bluetooth";
    rev = "main";
    sha256 = "sha256-RMcEgjiKgmjCI9cj8dVfedx4LaGMPAk48R62hbWZHew=";
  };

  hash = "sha256-D6g8rdsY0COHTCDcgTz+6RZ4IaWD6EsoGeli1qKIKSg=";
  buildMessage = "Building Bluetooth frontend...";

  meta = with lib; {
    description = "Bluetooth controls for Steam Deck";
    homepage = "https://github.com/Outpox/Bluetooth";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
