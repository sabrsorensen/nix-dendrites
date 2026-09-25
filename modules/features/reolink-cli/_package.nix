{
  lib,
  stdenvNoCC,
  fetchurl,
  reolink-cli-src,
  ...
}:
let
  # Version and release-asset hash both come from the pinned upstream repo, so
  # a flake.lock bump is the whole update.
  inherit (lib.importJSON "${reolink-cli-src}/package.json") version;
  asset = "reolink-cli-${version}-external-linux-x86_64.tar.gz";
  checksumFile = "${reolink-cli-src}/checksums/v${version}.sha256";
  checksumLine =
    lib.findFirst (line: lib.hasSuffix "  ${asset}" line)
      (throw "reolink-cli: no checksum for ${asset} in ${checksumFile}")
      (lib.splitString "\n" (lib.readFile checksumFile));
in
stdenvNoCC.mkDerivation {
  # This is intentionally a private package recipe, installed only on hosts
  # with my.host.features.reolinkCli (which also allows the unfree license).
  pname = "reolink-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/reolink/reolink-cli/releases/download/v${version}/${asset}";
    sha256 = lib.head (lib.splitString " " checksumLine);
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    tar -xzf "$src"
    install -d "$out/bin"
    while IFS= read -r -d "" executable; do
      install -Dm755 "$executable" "$out/bin/$(basename "$executable")"
    done < <(find . -type f -perm -0100 -print0)

    runHook postInstall
  '';

  meta = {
    description = "LAN-only CLI for Reolink cameras";
    homepage = "https://github.com/reolink/reolink-cli";
    license = lib.licenses.unfree;
    mainProgram = "reolink-cli";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
