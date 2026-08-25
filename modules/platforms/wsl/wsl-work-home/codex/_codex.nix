{ inputs }:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      codexPackage = inputs.codex-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      username = config.home.username;
      homeDirectory = config.home.homeDirectory;
      secretExports =
        lib.concatMapStringsSep "\n"
          (spec: ''
            if [ -r ${lib.escapeShellArg spec.path} ]; then
              export ${spec.env}="$(cat ${lib.escapeShellArg spec.path})"
            fi
          '')
          [
            {
              env = "GITHUB_NIXOS_MCP_TOKEN";
              path = config.sops.secrets.github_nixos_mcp_token.path;
            }
            {
              env = "HIGISH_GITHUB_NIXOS_MCP_TOKEN";
              path = config.sops.secrets.higish_github_nixos_mcp_token.path;
            }
            {
              env = "PULUMI_NIXOS_MCP_TOKEN";
              path = config.sops.secrets.pulumi_nixos_mcp_token.path;
            }
            {
              env = "CONTEXT7_API_KEY";
              path = config.sops.secrets.context7_api_key.path;
            }
            {
              env = "POSTMAN_API_KEY";
              path = config.sops.secrets.postman_nixos_mcp_token.path;
            }
            {
              env = "PERSONAL_ACCESS_TOKEN";
              path = config.sops.secrets.azdo_nixos_mcp_token.path;
            }
            {
              env = "SNYK_TOKEN";
              path = config.sops.secrets.snyk_nixos_mcp_token.path;
            }
          ];
      wrappedCodex = pkgs.symlinkJoin {
        name = "codex-wrapped-${lib.getVersion codexPackage}";
        paths = [ codexPackage ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/codex" --run ${lib.escapeShellArg secretExports}
        '';
      };
      herdrPackage = inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
      codexConfig = "${homeDirectory}/.codex/config.toml";
    in
    {
      options.my.features.wslCodex = lib.mkEnableOption "WSL work Codex profile";
      config = lib.mkIf config.my.features.wslCodex {
        home.packages = [
          pkgs.bubblewrap
          (pkgs.python3.withPackages (ps: [ ps.pyyaml ]))
        ]
        ++ lib.optional (pkgs ? spec-kit) pkgs.spec-kit;
        home.file.".codex/skills/herdr/SKILL.md" = {
          source = ./herdr-skill.md;
          force = true;
        };
        # Home Manager normally links this file from the Nix store.  Herdr's
        # Codex integration must update it to enable hooks, so the activation
        # bridge below turns the generated link into a mutable user file after
        # each generation has been linked.
        home.activation.herdrCodexPrepareConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          if [ -f ${lib.escapeShellArg codexConfig} ] && [ ! -L ${lib.escapeShellArg codexConfig} ]; then
            run mv -f ${lib.escapeShellArg codexConfig} ${lib.escapeShellArg "${codexConfig}.herdr-previous"}
          fi
        '';
        home.activation.herdrCodexIntegration = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          codex_home=${lib.escapeShellArg homeDirectory}/.codex
          run mkdir -p "$codex_home"
          if [ -L ${lib.escapeShellArg codexConfig} ]; then
            run cp --remove-destination "$(readlink -f ${lib.escapeShellArg codexConfig})" ${lib.escapeShellArg codexConfig}
          fi
          run ${lib.getExe herdrPackage} integration install codex
        '';
        programs.codex = {
          enable = true;
          package = wrappedCodex;
          enableMcpIntegration = true;
          settings = {
            features.hooks = true;
            model = "gpt-5.6-terra";
            model_reasoning_effort = "medium";
            notice.model_migrations = {
              "gpt-5.3-codex" = "gpt-5.5";
              "gpt-5.4" = "gpt-5.5";
            };
            personality = "pragmatic";
            skills.config = [
              {
                path = "${homeDirectory}/.codex/skills/herdr/SKILL.md";
                enabled = true;
              }
            ];
            projects = {
              "${homeDirectory}/src/".trust_level = "trusted";
              "${homeDirectory}/src/nix-dendrites".trust_level = "trusted";
              "${homeDirectory}/src/nix-dendrites-rewrite".trust_level = "trusted";
              "${homeDirectory}/src/nix-dendrites-broadcast".trust_level = "trusted";
            };
            mcp_servers = {
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
                env_http_headers.CONTEXT7_API_KEY = "CONTEXT7_API_KEY";
              };
              GitHub = {
                url = "https://api.githubcopilot.com/mcp";
                bearer_token_env_var = "GITHUB_NIXOS_MCP_TOKEN";
              };
              HigishGitHub = {
                url = "https://api.githubcopilot.com/mcp";
                bearer_token_env_var = "HIGISH_GITHUB_NIXOS_MCP_TOKEN";
              };
              HigiConfluence.url = "https://mcp.atlassian.com/v1/mcp/authv2";
              HigiJira.url = "https://mcp.atlassian.com/v1/mcp/authv2";
              Pulumi = {
                url = "https://mcp.ai.pulumi.com/mcp";
                bearer_token_env_var = "PULUMI_NIXOS_MCP_TOKEN";
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
            };
            hooks.state = {
              "${homeDirectory}/.codex/hooks.json:session_start:0:0" = {
                trusted_hash = "sha256:219a76f1453ea3d5eaa859c97679f86f7faf3d8669db007cb16e071381f1d573";
              };
            };
          };
        };
      };
    };
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.wsl-codex = homeModule;
}
