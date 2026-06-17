{
  inputs,
  lib,
  ...
}:
let
  certDir = "${inputs.nix-work-secrets}/certs";
  extraCertFiles =
    if builtins.pathExists certDir then
      map (file: "${certDir}/${file}") (builtins.attrNames (builtins.readDir certDir))
    else
      [ ];
in
{
  config,
  pkgs,
  ...
}:
let
  username = config.my.host.primaryInteractiveUser or "sam";
  sandboxCertPath = "/etc/ssl/certs/ca-bundle.crt";
  sandboxCertCompatPath = "/etc/ssl/certs/ca-certificates.crt";
  zscalerBundle = pkgs.runCommand "zscaler-ca-bundle.crt" { } ''
    cat \
      ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
      ${lib.concatMapStringsSep " " lib.escapeShellArg extraCertFiles} \
      > $out
  '';
  certEnvironment = {
    NODE_EXTRA_CA_CERTS = "${zscalerBundle}";
    SSL_CERT_FILE = sandboxCertPath;
    NIX_SSL_CERT_FILE = sandboxCertPath;
    REQUESTS_CA_BUNDLE = sandboxCertPath;
    CURL_CA_BUNDLE = sandboxCertPath;
    GIT_SSL_CAINFO = sandboxCertPath;
    CARGO_HTTP_CAINFO = sandboxCertPath;
    CARGO_NET_GIT_FETCH_WITH_CLI = "true";
  };
  nixDaemonCertEnvironment = lib.mapAttrs (_: value: lib.mkForce value) certEnvironment;
  impureEnvVars = [
    "SSL_CERT_FILE"
    "NIX_SSL_CERT_FILE"
    "REQUESTS_CA_BUNDLE"
    "CURL_CA_BUNDLE"
    "GIT_SSL_CAINFO"
    "CARGO_HTTP_CAINFO"
  ];
in
{
  environment.sessionVariables = certEnvironment;

  nix = {
    settings = {
      trusted-users = lib.mkAfter [ username ];
      experimental-features = lib.mkAfter [ "configurable-impure-env" ];
      sandbox = true;
      ssl-cert-file = "${zscalerBundle}";
      extra-sandbox-paths = [
        "${zscalerBundle}=${sandboxCertPath}"
        "${zscalerBundle}=${sandboxCertCompatPath}"
      ];
      "impure-env" = impureEnvVars;
    };
    extraOptions = lib.mkAfter ''
      !include ${config.sops.secrets.github_nixos_wsl_token.path}
    '';
  };

  systemd.services.nix-daemon.environment = nixDaemonCertEnvironment;
  security.pki.certificateFiles = extraCertFiles;

  sops = {
    defaultSopsFile = "${inputs.nix-work-secrets}/secrets/wsl.yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets.github_nixos_wsl_token = {
      owner = username;
      group = "root";
      mode = "0400";
    };
  };
}
