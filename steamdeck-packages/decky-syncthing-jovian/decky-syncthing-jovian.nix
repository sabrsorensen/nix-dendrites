{
  lib,
  nodejs,
  pnpm_9,
  fetchPnpmDeps,
  pnpmConfigHook,
  python3,
  stdenv,
}:

stdenv.mkDerivation rec {
  pname = "decky-syncthing";
  version = "0.3.0-jovian";
  src = ./decky-syncthing-jovian;
  hash = "sha256-nFFB1JLAjeKIgRSObZoI4Sl149ZwjpQR5jSlUhUVyUQ=";
  buildMessage = "Building Jovian Syncthing frontend...";
  meta = with lib; {
    description = "Jovian/NixOS-friendly Syncthing integration for Decky Loader";
    homepage = "https://github.com/ssorensen/nix-dendrites";
    license = licenses.mit;
    platforms = platforms.linux;
  };

}
