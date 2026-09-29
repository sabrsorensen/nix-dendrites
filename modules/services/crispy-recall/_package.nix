{
  lib,
  buildNpmPackage,
  nodejs_24,
  python3,
  crispy-recall-src,
}:
buildNpmPackage {
  pname = "crispy-recall";
  inherit ((lib.importJSON "${crispy-recall-src}/package.json")) version;

  src = crispy-recall-src;
  nodejs = nodejs_24;
  npmDepsHash = "sha256-/60FDxryS3mGt/w8QfsBv1819296EPTGBX9EqxPnti0=";

  # better-sqlite3's install script falls back to node-gyp once its prebuild
  # download fails in the sandbox; that build needs python.
  nativeBuildInputs = [ python3 ];

  # scripts/build.mjs bundles every entry point into dist/ and copies the
  # freshly rebuilt better_sqlite3.node beside them, which is exactly where
  # the bundles load it from (join(__dirname, 'better_sqlite3.node')). The
  # default `npm pack` install would drop that addon: package.json `files`
  # allowlists only the JS bundles, because upstream restages the addon per
  # machine from `recall install`, which Nix replaces.
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/crispy-recall"
    cp -r dist "$out/lib/crispy-recall/dist"
    runHook postInstall
  '';

  meta = {
    description = "Local search over past Claude Code and Codex session transcripts";
    homepage = "https://github.com/TheSylvester/crispy-recall";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
