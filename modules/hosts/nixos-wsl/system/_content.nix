{
  certDir,
  lib,
  pkgs,
  ...
}@args:
let
  extraCertFiles =
    if builtins.pathExists certDir then
      map (file: "${certDir}/${file}") (builtins.attrNames (builtins.readDir certDir))
    else
      [ ];
  # Use a stable output name so routine certificate changes do not create
  # a misleading replacement path.
  bundle = pkgs.runCommand "zscaler-ca-bundle.crt" { } ''
    cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt ${
      lib.concatMapStringsSep " " lib.escapeShellArg extraCertFiles
    } > "$out"
  '';
  certPath = "/etc/ssl/certs/ca-bundle.crt";
  certEnvironment = {
    NODE_EXTRA_CA_CERTS = "${bundle}";
    SSL_CERT_FILE = certPath;
    NIX_SSL_CERT_FILE = certPath;
    REQUESTS_CA_BUNDLE = certPath;
    CURL_CA_BUNDLE = certPath;
    GIT_SSL_CAINFO = certPath;
    CARGO_HTTP_CAINFO = certPath;
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";
  };
  contentArgs = args // {
    inherit
      bundle
      certEnvironment
      certPath
      extraCertFiles
      ;
  };
in
lib.mkMerge [
  (import ./_wsl-content.nix contentArgs)
  (import ./_certificates-content.nix contentArgs)
  (import ./_nix-content.nix contentArgs)
  (import ./_sops-content.nix contentArgs)
]
