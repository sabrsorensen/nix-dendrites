{
  lib,
  fetchFromGitHub,
  mkDeckyPlugin,
  writeTextFile,
  animationConfig ? null, # Optional: pre-built animation configuration
  callPackage ? null, # For building animation configs
}:

let
  # Build a simple animation configuration for the enhanced plugin
  buildNixAnimationConfig =
    {
      animationIds ? [ ],
      downloadAnimationIds ? [ ],
      movieOverrides ? [ ],
      bootAnimation ? null,
      suspendAnimation ? null,
      throbberAnimation ? null,
      randomize ? "all",
      forceIpv4 ? true,
    }:
    let
      normalizedMovieOverrides =
        if movieOverrides != [ ] then
          map (override: {
            movie = override.movie;
            animation_id = override.animationId or override.animation_id;
          }) movieOverrides
        else
          lib.filter (override: override.animation_id != null) [
            {
              movie = "boot";
              animation_id = bootAnimation;
            }
            {
              movie = "suspend";
              animation_id = suspendAnimation;
            }
            {
              movie = "throbber";
              animation_id = throbberAnimation;
            }
          ];

      nixConfig = {
        animation_ids = animationIds;
        download_animation_ids = if downloadAnimationIds != [ ] then downloadAnimationIds else animationIds;
        movie_overrides = normalizedMovieOverrides;
        boot_animation = bootAnimation;
        suspend_animation = suspendAnimation;
        throbber_animation = throbberAnimation;
        randomize = randomize;
        force_ipv4 = forceIpv4;
      };

      configFile = writeTextFile {
        name = "nix-animations.json";
        text = builtins.toJSON nixConfig;
      };
    in
    configFile;

  mkEnhancedAnimationChanger =
    {
      animationConfig ? null,
    }:
    mkDeckyPlugin {
  pname = "decky-sdh-animationchanger-enhanced";
  version = "unstable-jovian";

  src = fetchFromGitHub {
    owner = "TheLogicMaster";
    repo = "SDH-AnimationChanger";
    rev = "main";
    sha256 = "sha256-F9OKBmuX0Pux3KTPX6UYJ1RL05ZMso2h0uw/VlvQ8CU=";
  };

      hash = "sha256-2yKZ+HQPJM2Lh8IZ3SKxUJFE2fCQszbyMJGq+76G6vk=";

      postPatch = ''
        cp ${./decky-animation-changer-enhanced-main.py} main.py
      '';

      buildMessage = "Building frontend with pnpm...";
      extraInstall = lib.optionalString (animationConfig != null) ''
        cp ${animationConfig} $out/nix-animations.json
      '';
      useFastPermissions = true;
      meta = with lib; {
        description = "Animation Changer plugin for Decky Loader with Jovian copy-based uioverrides";
        homepage = "https://github.com/TheLogicMaster/SDH-AnimationChanger";
        license = licenses.gpl3;
        platforms = platforms.linux;
        maintainers = [ ];
      };
    };

  basePackage = mkEnhancedAnimationChanger {
    inherit animationConfig;
  };
in
basePackage.overrideAttrs (prev: {
  passthru = (prev.passthru or { }) // {
    withAnimations =
      args:
      mkEnhancedAnimationChanger {
        animationConfig = buildNixAnimationConfig args;
      };
  };
})
