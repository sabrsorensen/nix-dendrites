{
  bundle,
  certPath,
  config,
  lib,
  username,
  ...
}:
{
  nix = {
    settings = {
      trusted-users = lib.mkAfter [ username ];
      experimental-features = lib.mkAfter [ "configurable-impure-env" ];
      sandbox = true;
      ssl-cert-file = bundle;
      extra-sandbox-paths = [
        "${bundle}=${certPath}"
        "${bundle}=/etc/ssl/certs/ca-certificates.crt"
      ];
      "impure-env" = [
        "SSL_CERT_FILE"
        "NIX_SSL_CERT_FILE"
        "REQUESTS_CA_BUNDLE"
        "CURL_CA_BUNDLE"
        "GIT_SSL_CAINFO"
        "CARGO_HTTP_CAINFO"
      ];
    };
    extraOptions = lib.mkAfter ''
      !include ${config.sops.secrets.github_nixos_wsl_token.path}
    '';
  };
}
