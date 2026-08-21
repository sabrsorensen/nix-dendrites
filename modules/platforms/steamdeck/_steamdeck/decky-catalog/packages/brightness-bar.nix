{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
  pkgs,
}:
mkDeckyPlugin {
  pname = "decky-brightness-bar";
  version = "unstable";
  src = fetchFromGitHub {
    owner = "rasitayaz";
    repo = "decky-brightness-bar";
    rev = "main";
    hash = "sha256-pUA81PmMfNIu0184rSxw1LPw4HldzIJAFfmf/LyfiBQ=";
  };
  hash = "sha256-rHoJpFwYFokFb/kU/WOk7/o3vhbnn1sWRj5EPwV9V1Y=";
  # Upstream's pnpm-lock.yaml is lockfileVersion 6.0, too old for pnpm_11 to
  # force-convert under --frozen-lockfile; read it with the pnpm major it was
  # generated for instead of forcing a fresh (potentially drifted) one.
  pnpm = import ./_pnpm9.nix { inherit pkgs; };
  fetcherVersion = 3;
  buildMessage = "Building Brightness Bar frontend...";
  meta = with lib; {
    description = "Customizable brightness bar for Steam Deck";
    homepage = "https://github.com/rasitayaz/decky-brightness-bar";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
