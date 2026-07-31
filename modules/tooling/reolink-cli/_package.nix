{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}:
stdenvNoCC.mkDerivation {
  # This is intentionally a private package recipe. Kamino and Zaphod opt in
  # through their host modules and explicitly allow this proprietary binary.
  pname = "reolink-cli";
  version = "0.10.6";

  src = fetchurl {
    url = "https://github.com/reolink/reolink-cli/releases/download/v0.10.6/reolink-cli-0.10.6-external-linux-x86_64.tar.gz";
    hash = "sha256-xbuzk63IHUk4J5wlS74RRcVO/3/L5abqPrDgipNfCXQ=";
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
