{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
  animationConfig ? null,
}:
mkDeckyPlugin {
  pname = "decky-sdh-animationchanger-enhanced";
  version = "unstable-jovian";
  src = fetchFromGitHub {
    owner = "TheLogicMaster";
    repo = "SDH-AnimationChanger";
    rev = "main";
    hash = "sha256-F9OKBmuX0Pux3KTPX6UYJ1RL05ZMso2h0uw/VlvQ8CU=";
  };
  hash = "sha256-2yKZ+HQPJM2Lh8IZ3SKxUJFE2fCQszbyMJGq+76G6vk=";
  postPatch = ''
    cp ${./vendor/animation-changer-main.py} main.py
  '';
  extraInstall = lib.optionalString (animationConfig != null) ''
    cp ${animationConfig} "$out/nix-animations.json"
  '';
  executablePatterns = [ "*.py" ];
  executablePaths = [ ];
  meta = with lib; {
    description = "NixOS-enhanced Animation Changer plugin for Decky Loader";
    homepage = "https://github.com/TheLogicMaster/SDH-AnimationChanger";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
