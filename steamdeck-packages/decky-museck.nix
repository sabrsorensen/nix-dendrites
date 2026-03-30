{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-museck";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "Nezreka";
    repo = "Museck";
    rev = "main";
    sha256 = "sha256-JOHvQ85tpFGYTH5S57Coz5Hc2e8wBDWRiosdxTCAI/0=";
  };

  hash = "sha256-o7PQ7XMtaA3kypofskunp5/NaNcJFn+4CT1NIGm3MSI=";
  buildMessage = "Building Museck frontend...";
  verifyMainPy = false;

  meta = with lib; {
    description = "Music player for Steam Deck";
    homepage = "https://github.com/Nezreka/Museck";
    license = licenses.gpl3;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
