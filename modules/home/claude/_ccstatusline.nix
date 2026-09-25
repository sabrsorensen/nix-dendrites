{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  # Not in nixpkgs. The npm tarball is a single bundled script with no
  # runtime dependencies, so this just wraps it with node. To update, take
  # `version` and `dist.integrity` from
  # https://registry.npmjs.org/ccstatusline/latest.
  pname = "ccstatusline";
  version = "2.2.30";

  src = fetchurl {
    url = "https://registry.npmjs.org/ccstatusline/-/ccstatusline-${finalAttrs.version}.tgz";
    hash = "sha512-5pzYEFjag+oRAI8udChxiN3lKFtzcHhu8KAsEP3T/wU6u3DsT0QJ3fAL2J4Cr+eo9AqRalqvP4sYpDguzn/1HQ==";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/ccstatusline"
    cp -r . "$out/lib/ccstatusline"
    makeWrapper ${lib.getExe nodejs} "$out/bin/ccstatusline" \
      --add-flags "$out/lib/ccstatusline/dist/ccstatusline.js"

    runHook postInstall
  '';

  meta = {
    description = "Customizable statusline for Claude Code with powerline support and themes";
    homepage = "https://github.com/sirmalloc/ccstatusline";
    license = lib.licenses.mit;
    mainProgram = "ccstatusline";
    platforms = lib.platforms.all;
  };
})
