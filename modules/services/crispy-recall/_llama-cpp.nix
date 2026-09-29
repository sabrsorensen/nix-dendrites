{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  curl,
}:
# crispy-recall pins llama.cpp b5300, the last release shipping the
# `llama-embedding` binary, which it needs for every query embedding. nixpkgs'
# llama-cpp has since dropped that tool, so this repackages upstream's exact
# pinned prebuilt instead of the binary `recall install` would download into
# ~/.recall/bin (unpatched, it can't run on NixOS). Bump alongside
# crispy-recall's LLAMA_RELEASE_TAG (src/recall/embedder.ts).
stdenv.mkDerivation (finalAttrs: {
  pname = "crispy-recall-llama-cpp";
  version = "b5300";

  src = fetchzip {
    url = "https://github.com/ggml-org/llama.cpp/releases/download/${finalAttrs.version}/llama-${finalAttrs.version}-bin-ubuntu-x64.zip";
    hash = "sha256-TzmFNrTRUGZgtrEBr69ypUfLbRFeljJ05sWJjuTyDTg=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    curl
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 -t "$out/bin" bin/llama-embedding bin/llama-server
    install -Dm755 -t "$out/lib" bin/libllama.so bin/libggml*.so
    runHook postInstall
  '';

  # The prebuilt binaries look for their libraries beside themselves; point
  # the patched RUNPATH at $out/lib instead.
  preFixup = ''
    addAutoPatchelfSearchPath "$out/lib"
  '';

  meta = {
    description = "llama.cpp b5300 embedding binaries pinned by crispy-recall";
    homepage = "https://github.com/ggml-org/llama.cpp";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
