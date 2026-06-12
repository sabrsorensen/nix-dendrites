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
    sha256 = "sha256-KuHo9SmNcdob0PFlfG0E92vtHH9ndV/VdIk5cVx/14I=";
  };

  hash = "sha256-HNkAGz7I+JDa1n/eTsDy1CDYMCpI831Q+7TB9Nq8qeI=";

  prePatch = ''
    if [ -f pnpm-lock.yaml ]; then
      echo "Fixing pnpm lockfile version..."
      sed -i 's/lockfileVersion: .*/lockfileVersion: "6.0"/' pnpm-lock.yaml
    fi
  '';

  buildMessage = "Building AutoSuspend frontend...";

  meta = with lib; {
    description = "Automatically suspend Steam Deck on low power";
    homepage = "https://github.com/jurassicplayer/decky-autosuspend";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
