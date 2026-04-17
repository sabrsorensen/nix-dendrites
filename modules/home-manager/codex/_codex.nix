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
      optionalSecretPath =
        name:
        if (config ? sops) && builtins.hasAttr name config.sops.secrets then
          config.sops.secrets.${name}.path
        else
          null;
      wrapSecretEnv =
        envName: secretPath:
        lib.optionalString (secretPath != null) "--run 'export ${envName}=\"$(cat ${secretPath})\"'";
      codexWrapped = pkgs.symlinkJoin {
        name = "codex-wrapped";
        paths = [ codexPackage ];
        version = codexPackage.version;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/codex" \
            ${wrapSecretEnv "GITHUB_NIXOS_MCP_TOKEN" (optionalSecretPath "github_nixos_mcp_token")} \
            ${wrapSecretEnv "PULUMI_NIXOS_MCP_TOKEN" (optionalSecretPath "pulumi_nixos_mcp_token")} \
            ${wrapSecretEnv "CONTEXT7_API_KEY" (optionalSecretPath "context7_api_key")} \
            ${wrapSecretEnv "POSTMAN_API_KEY" (optionalSecretPath "postman_nixos_mcp_token")} \
            ${wrapSecretEnv "SNYK_TOKEN" (optionalSecretPath "snyk_nixos_mcp_token")}
        '';
      };
    in
    {
      home.packages = [ pkgs.bubblewrap ];

      programs.codex = {
        enable = true;
        package = codexWrapped;
        enableMcpIntegration = true;
        settings = {
          model = "gpt-5.4";
          personality = "pragmatic";

          mcp_servers = {
            Atlassian = {
              url = "https://mcp.atlassian.com/v1/mcp";
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
