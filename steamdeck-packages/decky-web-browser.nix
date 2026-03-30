{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-web-browser";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "jessebofill";
    repo = "DeckWebBrowser";
    rev = "master";
    sha256 = "sha256-qilaHvk/HiOaqBl1IgBLtfVoPaYph0yuoS+p7yG9aCE=";
  };

  hash = "sha256-c61m7jlyx4vTbalB7EVd0fc+TH/uFXeYRBxEIDEj2FE=";
  buildMessage = "Building DeckWebBrowser frontend...";
  executablePaths = [ "*/bin/*" ];

  meta = with lib; {
    description = "Simple web browser for Steam Deck";
    homepage = "https://github.com/jessebofill/DeckWebBrowser";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
