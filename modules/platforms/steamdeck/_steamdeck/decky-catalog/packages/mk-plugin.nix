{
  lib,
  fetchPnpmDeps,
  nodejs,
  pnpm_11,
  pnpmConfigHook,
  python3,
  stdenv,
}:
{
  pname,
  version,
  src,
  sourceRoot ? null,
  hash,
  meta ? { },
  pnpm ? pnpm_11,
  fetcherVersion ? 4,
  buildMessage ? "Building ${pname} frontend...",
  buildCommand ? "pnpm build",
  buildInputs ? [ ],
  extraNativeBuildInputs ? [ ],
  patches ? [ ],
  prePatch ? null,
  postPatch ? null,
  sourceReplacementScript ? null,
  preConfigure ? null,
  postConfigure ? null,
  preBuild ? null,
  postBuild ? null,
  extraInstallCheck ? "",
  extraInstall ? "",
  verifyMainPy ? true,
  verifyPluginJson ? true,
  executablePatterns ? [
    "*.py"
    "*.sh"
  ],
  executablePaths ? [ "*/bin/*" ],
}:
let
  userPreConfigure = preConfigure;
in
stdenv.mkDerivation {
  inherit
    pname
    version
    src
    meta
    buildInputs
    patches
    prePatch
    postPatch
    postConfigure
    preBuild
    postBuild
    sourceRoot
    ;

  preConfigure =
    lib.optionalString (sourceReplacementScript != null) ''
      ${python3}/bin/python3 ${sourceReplacementScript}
    ''
    + lib.optionalString (userPreConfigure != null) userPreConfigure;

  pnpmDeps = fetchPnpmDeps {
    inherit
      pname
      version
      src
      fetcherVersion
      hash
      pnpm
      ;
  };
  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    python3
  ]
  ++ extraNativeBuildInputs;

  buildPhase = ''
    runHook preBuild
    echo ${lib.escapeShellArg buildMessage}
    ${buildCommand}
    test -f dist/index.js || { echo "Frontend build did not produce dist/index.js"; exit 1; }
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r . "$out/"
    ${lib.optionalString verifyMainPy ''test -f "$out/main.py" || { echo "Plugin has no main.py"; exit 1; }''}
    ${lib.optionalString verifyPluginJson ''test -f "$out/plugin.json" || { echo "Plugin has no plugin.json"; exit 1; }''}
    ${extraInstallCheck}
    ${extraInstall}
    find "$out" -type f -exec chmod 644 {} +
    find "$out" -type d -exec chmod 755 {} +
    ${lib.concatMapStringsSep "\n" (
      pattern: "find \"$out\" -type f -name '${pattern}' -exec chmod +x {} +"
    ) executablePatterns}
    ${lib.concatMapStringsSep "\n" (
      path: "find \"$out\" -type f -path '${path}' -exec chmod +x {} +"
    ) executablePaths}
    runHook postInstall
  '';
}
