{
  inputs,
  ...
}:
{
  flake.modules.nixos.attic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.attic;
      localDomain = config.systemConstants.domain;
      envSecretName = "atticd-env";
      envSecretFile = "${inputs.nix-secrets}/env_files/atticd.env";
      hasEnvSecret = builtins.pathExists envSecretFile;
      clientConfigHome = "/var/lib/atticd/client-config";
      localHost = "127.0.0.1";
      localPort = 8080;
      localApiEndpoint = "http://${localHost}:${toString localPort}";
      publicCacheEndpoint = "https://${cfg.hostName}.${localDomain}/${cfg.cacheName}";
      serverAlias = cfg.serverAlias;
      bootstrapScript = pkgs.writeShellApplication {
        name = "attic-cache-bootstrap";
        runtimeInputs = with pkgs; [
          attic-client
          coreutils
          gnused
        ];
        text = ''
          set -eu

          export XDG_CONFIG_HOME=${lib.escapeShellArg clientConfigHome}
          mkdir -p "$XDG_CONFIG_HOME"

          cache_name=${lib.escapeShellArg cfg.cacheName}
          server_alias=${lib.escapeShellArg serverAlias}
          api_endpoint=${lib.escapeShellArg localApiEndpoint}
          public_cache_endpoint=${lib.escapeShellArg publicCacheEndpoint}

          token="$(atticd-atticadm make-token \
            --sub ${lib.escapeShellArg "atlas-bootstrap"} \
            --validity ${lib.escapeShellArg "1y"} \
            --create-cache "${cfg.cacheName}" \
            --pull "${cfg.cacheName}" \
            --push "${cfg.cacheName}" \
            --delete "${cfg.cacheName}" \
            --configure-cache "${cfg.cacheName}" \
            --configure-cache-retention "${cfg.cacheName}")"

          ${pkgs.attic-client}/bin/attic login "$server_alias" "$api_endpoint" "$token" >/dev/null

          if ! ${pkgs.attic-client}/bin/attic cache info "$cache_name" >/dev/null 2>&1; then
            ${pkgs.attic-client}/bin/attic cache create "$cache_name"
          fi

          ${
            if cfg.public then
              "${pkgs.attic-client}/bin/attic cache configure \"$cache_name\" --public >/dev/null"
            else
              "true"
          }

          echo "Attic cache is ready."
          echo "Cache endpoint: $public_cache_endpoint"
          ${pkgs.attic-client}/bin/attic cache info "$cache_name"
          echo
          echo "Add these settings to consumers after first bootstrap:"
          echo "  nix.settings.extra-substituters = [ \\\"$public_cache_endpoint\\\" ];"
          echo "  nix.settings.extra-trusted-public-keys = [ \\\"$( ${pkgs.attic-client}/bin/attic cache info \"$cache_name\" | sed -n 's/^ *Public Key: //p' )\\\" ];"
        '';
      };
      pushScript = pkgs.writeShellApplication {
        name = "attic-build-and-push";
        runtimeInputs = with pkgs; [
          attic-client
          bash
          coreutils
          nix
        ];
        text = ''
          set -euo pipefail

          export XDG_CONFIG_HOME=${lib.escapeShellArg clientConfigHome}
          mkdir -p "$XDG_CONFIG_HOME"

          if [ "$#" -eq 0 ]; then
            echo "usage: attic-build-and-push <installable> [<installable> ...]" >&2
            exit 2
          fi

          ${lib.getExe bootstrapScript} >/dev/null

          declare -A seen_paths=()
          store_paths=()

          while [ "$#" -gt 0 ]; do
            installable="$1"
            shift

            while IFS= read -r output_path; do
              while IFS= read -r store_path; do
                if [ -z "''${seen_paths[$store_path]+x}" ]; then
                  seen_paths[$store_path]=1
                  store_paths+=("$store_path")
                fi
              done < <(${pkgs.nix}/bin/nix path-info --recursive "$output_path")
            done < <(${pkgs.nix}/bin/nix build --no-link --print-out-paths "$installable")
          done

          if [ "''${#store_paths[@]}" -eq 0 ]; then
            echo "no store paths were produced" >&2
            exit 1
          fi

          ${pkgs.attic-client}/bin/attic push ${lib.escapeShellArg cfg.cacheName} "''${store_paths[@]}"
        '';
      };
      targetBasenamesPattern = lib.concatStringsSep "|" (
        map lib.escapeRegex (map lib.toLower cfg.autoPush.targetBasenames)
      );
      postBuildHook = pkgs.writeShellApplication {
        name = "attic-post-build-hook";
        runtimeInputs = with pkgs; [
          attic-client
          bash
          coreutils
          gnugrep
          nix
        ];
        text = ''
          set -euo pipefail

          export XDG_CONFIG_HOME=${lib.escapeShellArg clientConfigHome}
          mkdir -p "$XDG_CONFIG_HOME"

          if [ -z "''${OUT_PATHS:-}" ]; then
            exit 0
          fi

          declare -A matched_paths=()
          while IFS= read -r output_path; do
            base_name="$(basename "$output_path" | tr '[:upper:]' '[:lower:]')"
            if printf '%s\n' "$base_name" | grep -Eq '${targetBasenamesPattern}'; then
              matched_paths["$output_path"]=1
            fi
          done < <(printf '%s\n' $OUT_PATHS)

          if [ "''${#matched_paths[@]}" -eq 0 ]; then
            exit 0
          fi

          if ! ${lib.getExe bootstrapScript} >/dev/null 2>&1; then
            echo "warning: Attic bootstrap failed during post-build hook" >&2
            exit 0
          fi

          declare -A seen_paths=()
          store_paths=()

          for output_path in "''${!matched_paths[@]}"; do
            while IFS= read -r store_path; do
              if [ -z "''${seen_paths[$store_path]+x}" ]; then
                seen_paths[$store_path]=1
                store_paths+=("$store_path")
              fi
            done < <(${pkgs.nix}/bin/nix path-info --recursive "$output_path")
          done

          if [ "''${#store_paths[@]}" -eq 0 ]; then
            exit 0
          fi

          if ! ${pkgs.attic-client}/bin/attic push ${lib.escapeShellArg cfg.cacheName} "''${store_paths[@]}"; then
            echo "warning: Attic push failed during post-build hook" >&2
            exit 0
          fi
        '';
      };
    in
    {
      options.my.services.attic = {
        enable = lib.mkEnableOption "Attic binary cache service";

        hostName = lib.mkOption {
          type = lib.types.str;
          default = "attic";
        };

        cacheName = lib.mkOption {
          type = lib.types.str;
          default = "atlas";
        };

        public = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };

        serverAlias = lib.mkOption {
          type = lib.types.str;
          default = "atlas-local";
        };

        autoPush = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };

          targetBasenames = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "naboo"
              "nevarro"
              "emeraldecho"
            ];
          };
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = hasEnvSecret;
            message = "Attic requires ${envSecretFile} with ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=...";
          }
        ];

        my.localDns.records = [
          { hostname = cfg.hostName; }
        ];

        my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
          ''
            reverse_proxy /* ${localHost}:${toString localPort}
          ''
        ];

        sops.secrets.${envSecretName} = {
          owner = "root";
          group = "root";
          mode = "0400";
          format = "dotenv";
          sopsFile = envSecretFile;
          key = "";
        };

        services.atticd = {
          enable = true;
          environmentFile = config.sops.secrets.${envSecretName}.path;
        };

        nix.settings = lib.mkIf cfg.autoPush.enable {
          post-build-hook = lib.getExe postBuildHook;
        };

        environment.systemPackages = [
          pkgs.attic-client
          bootstrapScript
          postBuildHook
          pushScript
        ];
      };
    };
}
