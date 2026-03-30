{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-isthereanydeal";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "JtdeGraaf";
    repo = "IsThereAnyDeal-DeckyPlugin";
    rev = "main";
    sha256 = "sha256-QpY3tEuTde/NVLRX0OWLLqIHnGxUDTJTfNIot1dKLLk=";
  };

  hash = "sha256-lmhw7aYSmkblSStHu0Z/ykU+YPsi+2e/3jSeUU4VNgI=";
  buildMessage = "Building IsThereAnyDeal frontend...";
  executablePaths = [ "*/bin/*" ];

  meta = with lib; {
    description = "IsThereAnyDeal integration for Steam Deck";
    homepage = "https://github.com/JtdeGraaf/IsThereAnyDeal-DeckyPlugin";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
