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
    sha256 = "sha256-iRffRd13ABENTW4b1tFjaK40s2rvVbumeBPDsRIohjU=";
  };

  hash = "sha256-02S4/SRPo9hSioDwyPgPNBdfEurX9yaXbq8MbqwK8pY=";
  buildMessage = "Building Bluetooth frontend...";

  meta = with lib; {
    description = "Bluetooth controls for Steam Deck";
    homepage = "https://github.com/Outpox/Bluetooth";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
