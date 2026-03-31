{
  lib,
  fetchFromGitHub,
  nodejs,
  pnpm_9,
  fetchPnpmDeps,
  pnpmConfigHook,
  python3,
  stdenv,
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

in
stdenv.mkDerivation rec {
  pname = "decky-sdh-animationchanger-enhanced";
  version = "unstable-jovian";

  src = fetchFromGitHub {
    owner = "TheLogicMaster";
    repo = "SDH-AnimationChanger";
    rev = "main";
    sha256 = "sha256-F9OKBmuX0Pux3KTPX6UYJ1RL05ZMso2h0uw/VlvQ8CU=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    pnpm = pnpm_9;
    fetcherVersion = 3;
    hash = "sha256-2yKZ+HQPJM2Lh8IZ3SKxUJFE2fCQszbyMJGq+76G6vk=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm_9
    pnpmConfigHook
    python3
  ];

  postPatch = ''
    cp ${./decky-animation-changer-enhanced-main.py} main.py
  '';

  buildPhase = ''
    runHook preBuild

    # Build frontend with pnpm
    echo "Building frontend with pnpm..."
    pnpm build

    # Verify dist/index.js was built
    if [ ! -f dist/index.js ]; then
      echo "Error: Frontend build failed - dist/index.js not found"
      exit 1
    fi

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r * $out/

    # Ensure main.py and plugin.json exist
    if [ ! -f $out/main.py ]; then
      echo "Error: Plugin must contain a main.py file"
      exit 1
    fi
    if [ ! -f $out/plugin.json ]; then
      echo "Error: Plugin must contain a plugin.json file"
      exit 1
    fi

    # If animation config is provided, set it up as nix-animations.json
    ${lib.optionalString (animationConfig != null) ''
      echo "Setting up Nix animation configuration..."

      # Copy the nix-animations.json file
      cp ${animationConfig} $out/nix-animations.json

      echo "Nix animation configuration setup complete!"
      echo "Config: $out/nix-animations.json"
    ''}

    # Set proper permissions efficiently
    find $out -type f -exec chmod 644 {} + -o -type d -exec chmod 755 {} +
    find $out -type f -name "*.py" -exec chmod +x {} +
    find $out -type f -name "*.sh" -exec chmod +x {} +

    runHook postInstall
  '';

  passthru = {
    # Helper function for custom animation lists
    withAnimations =
      args:
      (stdenv.mkDerivation rec {
        inherit
          pname
          version
          src
          pnpmDeps
          nativeBuildInputs
          postPatch
          buildPhase
          ;

        installPhase = ''
          runHook preInstall

          mkdir -p $out
          cp -r * $out/

          # Ensure main.py and plugin.json exist
          if [ ! -f $out/main.py ]; then
            echo "Error: Plugin must contain a main.py file"
            exit 1
          fi
          if [ ! -f $out/plugin.json ]; then
            echo "Error: Plugin must contain a plugin.json file"
            exit 1
          fi

          # Copy the nix-animations.json file
          cp ${buildNixAnimationConfig args} $out/nix-animations.json

          echo "Animation configuration setup complete!"
          echo "Config: $out/nix-animations.json"

          # Set proper permissions efficiently in single pass
          find $out \( -type f -name "*.py" -o -name "*.sh" \) -exec chmod +x {} + \
            -o -type f -exec chmod 644 {} + \
            -o -type d -exec chmod 755 {} +

          runHook postInstall
        '';
      });
  };

  meta = with lib; {
    description = "Animation Changer plugin for Decky Loader with Jovian copy-based uioverrides";
    homepage = "https://github.com/TheLogicMaster/SDH-AnimationChanger";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
