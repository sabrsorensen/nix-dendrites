{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-steamgriddb";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "SteamGridDB";
    repo = "decky-steamgriddb";
    rev = "HEAD";
    sha256 = "sha256-3+7k24L3nYW7zoKzTPC3khOubs00plbGoIuFmxT6jB8=";
  };

  hash = "sha256-FRIkp2GuP/kVaxpq7Sn6DYsUbE2O/g8vxin+pl+3ZNw=";
  buildMessage = "Building SteamGridDB frontend...";

  meta = with lib; {
    description = "SteamGridDB integration for Steam Deck - apply custom artwork from SteamGridDB";
    homepage = "https://github.com/SteamGridDB/decky-steamgriddb";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
