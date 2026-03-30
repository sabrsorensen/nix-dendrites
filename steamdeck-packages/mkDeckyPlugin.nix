{
  lib,
  fetchPnpmDeps,
  nodejs,
  pnpm_9,
  pnpmConfigHook,
  python3,
  stdenv,
}:

{
  pname,
  version,
  src,
  meta ? { },
  hash,
  fetcherVersion ? 3,
  extraNativeBuildInputs ? [ ],
  buildInputs ? [ ],
  patches ? [ ],
  prePatch ? null,
  postPatch ? null,
  preConfigure ? null,
  postConfigure ? null,
  preBuild ? null,
  postBuild ? null,
  buildCommand ? "pnpm build",
  buildMessage ? "Building ${pname} frontend...",
  extraInstallCheck ? "",
  extraInstall ? "",
  verifyMainPy ? true,
  verifyPluginJson ? true,
  executablePatterns ? [
    "*.py"
    "*.sh"
  ],
  executablePaths ? [ "*/bin/*" ],
  useFastPermissions ? false,
}:

stdenv.mkDerivation rec {
  inherit
    pname
    version
    src
    meta
    buildInputs
    patches
    ;

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    pnpm = pnpm_9;
    inherit fetcherVersion hash;
  };

  nativeBuildInputs = [
    nodejs
    pnpm_9
    pnpmConfigHook
    python3
  ] ++ extraNativeBuildInputs;

  inherit
    prePatch
    postPatch
    preConfigure
    postConfigure
    preBuild
    postBuild
    ;

  buildPhase = ''
    runHook preBuild

    echo ${lib.escapeShellArg buildMessage}
    ${buildCommand}

    if [ ! -f dist/index.js ]; then
      echo "Error: Frontend build failed - dist/index.js not found"
      exit 1
    fi

    runHook postBuild
  '';

  installPhase =
    let
      chmodPatterns = lib.concatMapStringsSep "\n" (
        pattern: "find $out -type f -name '${pattern}' -exec chmod +x {} \\;"
      ) executablePatterns;
      chmodPaths = lib.concatMapStringsSep "\n" (
        path: "find $out -type f -path '${path}' -exec chmod +x {} \\;"
      ) executablePaths;
      permissionBlock =
        if useFastPermissions then
          ''
            find $out -type f -exec chmod 644 {} + -o -type d -exec chmod 755 {} +
            ${lib.concatMapStringsSep "\n" (
              pattern: "find $out -type f -name '${pattern}' -exec chmod +x {} +"
            ) executablePatterns}
            ${lib.concatMapStringsSep "\n" (
              path: "find $out -type f -path '${path}' -exec chmod +x {} +"
            ) executablePaths}
          ''
        else
          ''
            find $out -type f -exec chmod 644 {} \;
            find $out -type d -exec chmod 755 {} \;
            ${chmodPatterns}
            ${chmodPaths}
          '';
    in
    ''
      runHook preInstall

      mkdir -p $out
      cp -r * $out/

      ${lib.optionalString verifyMainPy ''
        if [ ! -f $out/main.py ]; then
          echo "Error: Plugin must contain a main.py file"
          exit 1
        fi
      ''}

      ${lib.optionalString verifyPluginJson ''
        if [ ! -f $out/plugin.json ]; then
          echo "Error: Plugin must contain a plugin.json file"
          exit 1
        fi
      ''}

      ${extraInstallCheck}
      ${extraInstall}

      ${permissionBlock}

      runHook postInstall
    '';
}
