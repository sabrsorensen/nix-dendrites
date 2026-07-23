{ lib, mkDeckyPlugin }:
mkDeckyPlugin {
  pname = "decky-syncthing";
  version = "0.3.0-jovian";
  src = ./vendor/syncthing;
  hash = "sha256-nFFB1JLAjeKIgRSObZoI4Sl149ZwjpQR5jSlUhUVyUQ=";
  buildMessage = "Building Jovian Syncthing frontend...";
  meta = with lib; {
    description = "Jovian/NixOS-friendly Syncthing integration for Decky Loader";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
