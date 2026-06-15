{
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.codex =
    {
      config,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      codexPackage = inputs.codex-nix.packages.${system}.default;
      secretWrapArgsFromSpecs = import ../../../lib/secret-wrap-args.nix { inherit lib; };
      optionalSecretPath =
        name:
        if (config ? sops) && builtins.hasAttr name config.sops.secrets then
          config.sops.secrets.${name}.path
        else
          null;
      codexSecretWrapArgs = secretWrapArgsFromSpecs [
        {
          envName = "GITHUB_NIXOS_MCP_TOKEN";
          secretPath = optionalSecretPath "github_nixos_mcp_token";
        }
        {
          envName = "HIGISH_GITHUB_NIXOS_MCP_TOKEN";
          secretPath = optionalSecretPath "higish_github_nixos_mcp_token";
        }
        {
          envName = "PULUMI_NIXOS_MCP_TOKEN";
          secretPath = optionalSecretPath "pulumi_nixos_mcp_token";
        }
        {
          envName = "CONTEXT7_API_KEY";
          secretPath = optionalSecretPath "context7_api_key";
        }
        {
          envName = "POSTMAN_API_KEY";
          secretPath = optionalSecretPath "postman_nixos_mcp_token";
        }
        {
          envName = "PERSONAL_ACCESS_TOKEN";
          secretPath = optionalSecretPath "azdo_nixos_mcp_token";
        }
        {
          envName = "SNYK_TOKEN";
          secretPath = optionalSecretPath "snyk_nixos_mcp_token";
        }
      ];
      renderedCodexSecretWrapArgs = lib.optionalString (codexSecretWrapArgs != [ ]) ''
                \
        ${lib.concatStringsSep " \\\n            " codexSecretWrapArgs}
      '';
      codexWrapped = pkgs.symlinkJoin {
        name = "codex-wrapped";
        paths = [ codexPackage ];
        version = codexPackage.version;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/codex"${renderedCodexSecretWrapArgs}
        '';
      };
    in
    {
      home.packages =
        [ pkgs.bubblewrap ]
        ++ lib.optional (pkgs ? spec-kit) pkgs.spec-kit
        ++ [
          (pkgs.python3.withPackages (ps: with ps; [ pyyaml ]))
        ];

      programs.codex = {
        enable = true;
        package = codexWrapped;
        enableMcpIntegration = true;
        settings = {
          model = "gpt-5.4";
          model_reasoning_effort = "medium";
          notice.model_migrations = {
            "gpt-5.3-codex" = "gpt-5.5";
            "gpt-5.4" = "gpt-5.5";
          };
          personality = "pragmatic";
          projects."/home/ssorensen/src/nix-dendrites" = {
            trust_level = "trusted";
          };
          projects."/home/ssorensen/src/*" = {
            trust_level = "trusted";
          };
          projects."/home/ssorensen/higi/*" = {
            trust_level = "trusted";
          };
          tui.model_availability_nux = {
            "gpt-5.5" = 1;
          };

          mcp_servers = {
            Atlassian = {
              url = "https://mcp.atlassian.com/v1/mcp";
            };
            AZDOLocal = {
              command = "npx";
              args = [
                "-y"
                "@azure-devops/mcp@next"
                "higicore"
                "--authentication"
                "pat"
              ];
              env_vars = [ "PERSONAL_ACCESS_TOKEN" ];
              startup_timeout_sec = 300;
            };
            Context7 = {
              url = "https://mcp.context7.com/mcp";
              env_http_headers = {
                CONTEXT7_API_KEY = "CONTEXT7_API_KEY";
              };
            };
            GitHub = {
              url = "https://api.githubcopilot.com/mcp";
              bearer_token_env_var = "GITHUB_NIXOS_MCP_TOKEN";
            };
            HigishGitHub = {
              url = "https://api.githubcopilot.com/mcp";
              bearer_token_env_var = "HIGISH_GITHUB_NIXOS_MCP_TOKEN";
            };
            Postman = {
              command = "npx";
              args = [
                "@postman/postman-mcp-server"
                "--full"
                "--region"
                "us"
              ];
              env_vars = [ "POSTMAN_API_KEY" ];
            };
            Snyk = {
              command = "npx";
              args = [
                "-y"
                "snyk@latest"
                "mcp"
                "-t"
                "stdio"
              ];
              env_vars = [ "SNYK_TOKEN" ];
              startup_timeout_sec = 300;
            };
            Pulumi = {
              url = "https://mcp.ai.pulumi.com/mcp";
              bearer_token_env_var = "PULUMI_NIXOS_MCP_TOKEN";
            };
          };
        };
      };
    };
}
