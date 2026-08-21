{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:
mkDeckyPlugin {
  pname = "decky-autosuspend";
  version = "2.2.0";
  src = fetchFromGitHub {
    owner = "jurassicplayer";
    repo = "decky-autosuspend";
    rev = "v2.2.0";
    hash = "sha256-KuHo9SmNcdob0PFlfG0E92vtHH9ndV/VdIk5cVx/14I=";
  };
  hash = "sha256-AuRN6du7jkkKq6LgMcEAT5BdZ3D4axtZgNblIp7Lks8=";
  meta = with lib; {
    description = "Automatically suspend Steam Deck on low power";
    homepage = "https://github.com/jurassicplayer/decky-autosuspend";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
