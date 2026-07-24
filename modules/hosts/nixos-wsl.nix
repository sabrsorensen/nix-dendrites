{
  config,
  inputs,
  lib,
  ...
}:
let
  workModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = "ssorensen";
      certDir = "${inputs.nix-work-secrets}/certs";
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
    in
    {
      wsl = {
        defaultUser = username;
        docker-desktop.enable = true;
        interop.register = true;
        startMenuLaunchers = true;
        wslConf.interop = {
          enabled = true;
          appendWindowsPath = true;
        };
      };

      users.users.${username}.extraGroups = [ "docker" ];
      services.openssh.openFirewall = lib.mkForce false;
      programs.nix-ld.libraries = with pkgs; [
        icu
        openssl
        zlib
        stdenv.cc.cc.lib
      ];
      environment.systemPackages = with pkgs; [
        gnumake
        python3
        ripgrep
        sops
        ssh-to-age
        wget
      ];
      programs.fish.enable = true;
      environment.sessionVariables = certEnvironment;

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
      systemd.services.nix-daemon.environment = lib.mapAttrs (
        _: value: lib.mkForce value
      ) certEnvironment;
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
in
{
  imports = lib.optional (inputs ? nixos-wsl) ./_nixos-wsl.nix;
  flake.nixosConfigurations."nixos-wsl" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      inputs.nixos-wsl.nixosModules.default
      workModule
      {
        networking.hostName = "NixOS-WSL";
        wsl.enable = true;
        my.host = {
          name = "NixOS-WSL";
          formFactor = "vm";
          home.enable = true;
          # WSL is a work machine and remains a workstation for shared local
          # tooling and workstation-scoped policy such as printer discovery.
          roles = {
            workstation = true;
            wsl = true;
          };
          features.nix-ld = true;
        };
        my.deployment = {
          # Declare the checkout explicitly so `nh` and local helpers use the
          # intended repository path.
          localFlakePath = "/home/ssorensen/src/nix-dendrites";
        };
      }
    ];
  };
}
