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
  flake.modules.nixos.wsl-base =
    {
      config,
      pkgs,
      ...
    }:
    let
      username = config.my.wslUsername;
      sandboxCertPath = "/etc/ssl/certs/ca-bundle.crt";
      sandboxCertCompatPath = "/etc/ssl/certs/ca-certificates.crt";
      zscalerBundle = pkgs.runCommand "zscaler-ca-bundle.crt" { } ''
        cat \
          ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
          ${lib.concatMapStringsSep " " lib.escapeShellArg extraCertFiles} \
          > $out
      '';
    in
    {
      imports = [ inputs.nixos-wsl.nixosModules.wsl ];

      options.my.wslUsername = lib.mkOption {
        type = lib.types.str;
        default = "sam";
        description = "Primary username for the WSL host configuration.";
      };

      config = {
        networking.hostName = lib.mkDefault "NixOS-WSL";
        time.timeZone = lib.mkDefault "America/Boise";

        wsl = {
          enable = true;
          defaultUser = username;
          docker-desktop.enable = true;
          interop.register = true;
          startMenuLaunchers = true;
          wslConf.interop = {
            enabled = true;
            appendWindowsPath = true;
          };
        };

        environment.sessionVariables = {
          NODE_EXTRA_CA_CERTS = "${zscalerBundle}";
          SSL_CERT_FILE = sandboxCertPath;
          NIX_SSL_CERT_FILE = sandboxCertPath;
          REQUESTS_CA_BUNDLE = sandboxCertPath;
          CURL_CA_BUNDLE = sandboxCertPath;
          GIT_SSL_CAINFO = sandboxCertPath;
          CARGO_HTTP_CAINFO = sandboxCertPath;
          CARGO_NET_GIT_FETCH_WITH_CLI = "true";
        };

        users.users.${username}.extraGroups = [ "docker" ];

        services.openssh.openFirewall = lib.mkForce false;

        programs.nix-ld = {
          enable = true;
          libraries = with pkgs; [
            icu
            openssl
            zlib
            stdenv.cc.cc.lib
          ];
        };

        environment.systemPackages = with pkgs; [
          gnumake
          python3
          ripgrep
          sops
          ssh-to-age
          wget
        ];

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

        systemd.services.nix-daemon.environment = {
          REQUESTS_CA_BUNDLE = lib.mkForce sandboxCertPath;
          SSL_CERT_FILE = lib.mkForce sandboxCertPath;
          NIX_SSL_CERT_FILE = lib.mkForce sandboxCertPath;
          CURL_CA_BUNDLE = lib.mkForce sandboxCertPath;
          GIT_SSL_CAINFO = lib.mkForce sandboxCertPath;
          CARGO_HTTP_CAINFO = lib.mkForce sandboxCertPath;
          CARGO_NET_GIT_FETCH_WITH_CLI = lib.mkForce "true";
          NODE_EXTRA_CA_CERTS = lib.mkForce "${zscalerBundle}";
        };

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
      };
    };
}
