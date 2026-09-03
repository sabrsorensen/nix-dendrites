{ lib, mkDeckyPlugin }:
mkDeckyPlugin {
  pname = "decky-syncthing";
  version = "0.3.0-jovian";
  src = ./assets/vendor/syncthing;
  hash = "sha256-4R6z0nEXV9DWYR1Zj2vRNfR3U+coYuOoZ8rBxWem9DE=";
  buildMessage = "Building Jovian Syncthing frontend...";
  meta = with lib; {
    description = "Jovian/NixOS-friendly Syncthing integration for Decky Loader";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
