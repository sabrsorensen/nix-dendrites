{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-audio-loader";
  version = "1.6.1";

  src = fetchFromGitHub {
    owner = "DeckThemes";
    repo = "SDH-AudioLoader";
    rev = "main";
    sha256 = "sha256-9UQOMyeaofrbw7KSNn1kgdgeeDSjqLJFtYYO+EYKwGo=";
  };

  hash = "sha256-eKMmkRemqx7jOnnGH5hdMt11c9bPiYlInu4ru9FLyfk=";
  buildMessage = "Building AudioLoader frontend...";
  executablePaths = [ "*/bin/*" ];

  meta = with lib; {
    description = "Audio pack loader for Steam Deck - replace Steam UI sounds and add music";
    homepage = "https://github.com/DeckThemes/SDH-AudioLoader";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
