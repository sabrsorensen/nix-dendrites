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
  # Python packages to vendor into the plugin's py_modules/ directory. Decky
  # Loader puts py_modules/ on sys.path itself, so this is all the wiring a
  # backend dependency needs. The frontend `pnpm build` here is the only build
  # step that runs — the Decky store's own build additionally does
  # `pip install -r requirements.txt --target py_modules` (and some plugins'
  # package.sh vendor extra git sources the same way), which has no
  # network-free equivalent, so each such dependency is named here explicitly
  # as its nixpkgs package. Check a plugin's `requirements.txt` and its
  # main.py imports when adding it.
  pythonDeps ? [ ],
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
    ${lib.optionalString (pythonDeps != [ ]) ''
      echo "Vendoring ${toString (builtins.length pythonDeps)} Python dependency tree(s) into py_modules/"
      mkdir -p "$out/py_modules"
      for site in ${lib.escapeShellArgs (map (d: "${d}/${python3.sitePackages}") pythonDeps)}; do
        test -d "$site" || { echo "python dep has no ${python3.sitePackages}: $site"; exit 1; }
        cp -rn --no-preserve=mode "$site"/. "$out/py_modules/"
      done
      # Drop packaging metadata: the plugin adds py_modules/ to sys.path
      # directly and never runs an installer that would read it.
      find "$out/py_modules" -maxdepth 1 \( -name '*.dist-info' -o -name '*.egg-info' -o -name '*.pth' \) -exec rm -rf {} +
      find "$out/py_modules" -name '__pycache__' -type d -exec rm -rf {} +
    ''}
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
