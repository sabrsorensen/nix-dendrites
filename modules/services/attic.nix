{ inputs, ... }:
{
  flake.modules.nixos.attic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.attic;
      envSecretFile = "${inputs.nix-secrets}/env_files/atticd.env";
      clientConfigHome = "/var/lib/atticd/client-config";
      domain = builtins.replaceStrings [ "\n" ] [ "" ] (
        builtins.readFile "${inputs.nix-secrets}/domain.txt"
      );
      cacheEndpoint = "https://${cfg.hostName}.${domain}/${cfg.cacheName}";
      localApiEndpoint = "http://127.0.0.1:8080";
      bootstrap = pkgs.writeShellApplication {
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
          cd /

          cache_name=${lib.escapeShellArg cfg.cacheName}
          server_alias=${lib.escapeShellArg cfg.serverAlias}
          api_endpoint=${lib.escapeShellArg localApiEndpoint}
          public_cache_endpoint=${lib.escapeShellArg cacheEndpoint}

          token="$(atticd-atticadm make-token \
            --sub ${lib.escapeShellArg "atlas-bootstrap"} \
            --validity ${lib.escapeShellArg "1y"} \
            --create-cache "$cache_name" \
            --pull "$cache_name" \
            --push "$cache_name" \
            --delete "$cache_name" \
            --configure-cache "$cache_name" \
            --configure-cache-retention "$cache_name")"

          ${pkgs.attic-client}/bin/attic login "$server_alias" "$api_endpoint" "$token" >/dev/null
          ${pkgs.attic-client}/bin/attic cache create "$cache_name" >/dev/null 2>&1 || true
          ${lib.optionalString cfg.public "${pkgs.attic-client}/bin/attic cache configure \"$cache_name\" --public >/dev/null"}

          echo "Attic cache is ready."
          echo "Cache endpoint: $public_cache_endpoint"
          ${pkgs.attic-client}/bin/attic cache info "$cache_name"
          echo
          echo "Add these settings to consumers after first bootstrap:"
          echo "  nix.settings.extra-substituters = [ \\\"$public_cache_endpoint\\\" ];"
          echo "  nix.settings.extra-trusted-public-keys = [ \\\"$( ${pkgs.attic-client}/bin/attic cache info \"$cache_name\" | sed -n 's/^ *Public Key: //p' )\\\" ];"
        '';
      };
      push = pkgs.writeShellApplication {
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
          ${lib.getExe bootstrap} >/dev/null

          declare -A seen_paths=()
          store_paths=()
          while [ "$#" -gt 0 ]; do
            installable="$1"; shift
            while IFS= read -r output_path; do
              while IFS= read -r store_path; do
                if [ -z "''${seen_paths[$store_path]+x}" ]; then
                  seen_paths[$store_path]=1
                  store_paths+=("$store_path")
                fi
              done < <(nix path-info --recursive "$output_path")
            done < <(nix build --no-link --print-out-paths "$installable")
          done
          if [ "''${#store_paths[@]}" -eq 0 ]; then
            echo "no store paths were produced" >&2
            exit 1
          fi
          attic push ${lib.escapeShellArg cfg.cacheName} "''${store_paths[@]}"
        '';
      };
      targetPattern = lib.concatStringsSep "|" (
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
          [ -n "''${OUT_PATHS:-}" ] || exit 0

          declare -A matched_paths=() seen_paths=()
          store_paths=()
          while IFS= read -r output_path; do
            base_name="$(basename "$output_path" | tr '[:upper:]' '[:lower:]')"
            if printf '%s\n' "$base_name" | grep -Eq '${targetPattern}'; then
              matched_paths["$output_path"]=1
            fi
          done < <(printf '%s\n' "$OUT_PATHS")
          [ "''${#matched_paths[@]}" -gt 0 ] || exit 0
          ${lib.getExe bootstrap} >/dev/null 2>&1 || { echo "warning: Attic bootstrap failed during post-build hook" >&2; exit 0; }
          for output_path in "''${!matched_paths[@]}"; do
            while IFS= read -r store_path; do
              if [ -z "''${seen_paths[$store_path]+x}" ]; then
                seen_paths[$store_path]=1
                store_paths+=("$store_path")
              fi
            done < <(nix path-info --recursive "$output_path")
          done
          [ "''${#store_paths[@]}" -gt 0 ] || exit 0
          attic push ${lib.escapeShellArg cfg.cacheName} "''${store_paths[@]}" || echo "warning: Attic push failed during post-build hook" >&2
        '';
      };
    in
    {
      options.my.attic = {
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

      config = lib.mkIf config.my.host.services.attic {
        assertions = [
          {
            assertion = builtins.pathExists envSecretFile;
            message = "Attic requires ${envSecretFile} with ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64.";
          }
        ];
        my.localDns.records = [ { hostname = cfg.hostName; } ];
        my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [ "reverse_proxy /* 127.0.0.1:8080" ];
        sops.secrets.atticd-env = {
          owner = "root";
          group = "root";
          mode = "0400";
          format = "dotenv";
          sopsFile = envSecretFile;
          key = "";
        };
        services.atticd = {
          enable = true;
          environmentFile = config.sops.secrets.atticd-env.path;
        };
        nix.settings = lib.mkIf cfg.autoPush.enable { post-build-hook = lib.getExe postBuildHook; };
        environment.systemPackages = [
          pkgs.attic-client
          bootstrap
          push
          postBuildHook
        ];
      };
    };
}
