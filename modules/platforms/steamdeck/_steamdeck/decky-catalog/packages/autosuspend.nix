{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
  pkgs,
}:
let
  writeSourceReplacementScript = import ./_write-source-replacement-script.nix { inherit pkgs; };
  sourceReplacementScript = writeSourceReplacementScript {
    scriptName = "decky-autosuspend-lockfile";
    defaultFile = "pnpm-lock.yaml";
    replacements = [
      {
        kind = "regex";
        reason = "Normalize the lockfile version to the format expected by fetchPnpmDeps.";
        pattern = "lockfileVersion: .*";
        replacement = ''lockfileVersion: "6.0"'';
        expectedCount = 1;
      }
    ];
  };
in
mkDeckyPlugin {
  pname = "decky-autosuspend";
  version = "2.2.0";
  src = fetchFromGitHub {
    owner = "jurassicplayer";
    repo = "decky-autosuspend";
    rev = "v2.2.0";
    hash = "sha256-KuHo9SmNcdob0PFlfG0E92vtHH9ndV/VdIk5cVx/14I=";
  };
  hash = "sha256-HNkAGz7I+JDa1n/eTsDy1CDYMCpI831Q+7TB9Nq8qeI=";
  inherit sourceReplacementScript;
  meta = with lib; {
    description = "Automatically suspend Steam Deck on low power";
    homepage = "https://github.com/jurassicplayer/decky-autosuspend";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
