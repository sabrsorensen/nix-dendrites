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
    hash = "sha256-niK2O+5Te0wVR9BJqN0/yE4i0cEtveLO9+mkj5JolnM=";
  };
  hash = "sha256-Vvr6HTSR6YXfSuzPLIqSFH4kl3RAHNjVEiWwcKy8eu8=";
  executablePaths = [ "*/bin/*" ];
  meta = with lib; {
    description = "Notifications for free games on Steam, GOG, and Epic Games";
    homepage = "https://github.com/jwhitlow45/free-loader";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
