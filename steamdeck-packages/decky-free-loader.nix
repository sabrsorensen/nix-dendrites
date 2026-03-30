{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

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
  extraInstall = ''
    echo "Fixing Free Loader plugin import path for NixOS..."
    sed -i 's|sys\.path\.append(os\.path\.abspath("\.\.\/plugins\/free-loader"))|sys.path.append(os.path.dirname(os.path.abspath(__file__)))|' $out/main.py
  '';

  meta = with lib; {
    description = "Notifications for free games on Steam, GOG, and Epic Games";
    homepage = "https://github.com/jwhitlow45/free-loader";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
