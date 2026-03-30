{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
}:

mkDeckyPlugin {
  pname = "decky-animation-changer";
  version = "unstable-jovian";

  src = fetchFromGitHub {
    owner = "TheLogicMaster";
    repo = "SDH-AnimationChanger";
    rev = "main";
    sha256 = "sha256-F9OKBmuX0Pux3KTPX6UYJ1RL05ZMso2h0uw/VlvQ8CU=";
  };

  hash = "sha256-2yKZ+HQPJM2Lh8IZ3SKxUJFE2fCQszbyMJGq+76G6vk=";
  patches = [ ./patches/decky-animation-changer-jovian.patch ];
  buildMessage = "Building frontend with pnpm...";
  useFastPermissions = true;
  executablePatterns = [ "*.py" ];
  executablePaths = [ ];

  meta = with lib; {
    description = "Animation Changer plugin for Decky Loader with Jovian copy-based uioverrides";
    homepage = "https://github.com/TheLogicMaster/SDH-AnimationChanger";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
