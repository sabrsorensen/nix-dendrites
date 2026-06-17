{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
  pkgs,
  writeSourceReplacementScript,
}:

let
  sourceReplacementScript = writeSourceReplacementScript pkgs {
    scriptName = "decky-free-loader-import-path";
    defaultFile = "main.py";
    replacements = [
      {
        kind = "literal";
        reason = "Resolve the plugin-local import path without assuming Decky's mutable plugins directory layout.";
        old = ''sys.path.append(os.path.abspath("../plugins/free-loader"))'';
        new = "sys.path.append(os.path.dirname(os.path.abspath(__file__)))";
        expectedCount = 1;
      }
    ];
  };
in
mkDeckyPlugin {
  pname = "decky-free-loader";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "jwhitlow45";
    repo = "free-loader";
    rev = "main";
    sha256 = "sha256-MCpk5v3GelpOIKqkqyESS6qhM4rWOndhf0X1ybr5g+k=";
  };

  hash = "sha256-JiZYfSiDUEXSZ0Vwv/B/+twXm/fHOr6uQMeFc/FCKPI=";
  buildMessage = "Building Free Loader frontend...";
  executablePaths = [ "*/bin/*" ];
  sourceReplacementScript = sourceReplacementScript;

  meta = with lib; {
    description = "Notifications for free games on Steam, GOG, and Epic Games";
    homepage = "https://github.com/jwhitlow45/free-loader";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
