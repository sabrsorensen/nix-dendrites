{
  flake.modules.homeManager."mcp-work" =
    {
      ...
    }:
    {
      programs.mcp = {
        enable = true;
        servers = {
          Azure = {
            command = "uvx";
            args = [
              "--from"
              "msmcp-azure"
              "azmcp"
              "server"
              "start"
            ];
            env = {
              AZURE_TOKEN_CREDENTIALS = "AzureCliCredential";
            };
            startup_timeout_sec = 300;
          };

          NixOS.env = {
            SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
            REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
            CURL_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
            NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
          };

          Postman = {
            command = "npx";
            args = [
              "@postman/postman-mcp-server"
              "--full"
              "--region"
              "us"
            ];
            env = {
              POSTMAN_API_KEY = "\${env:POSTMAN_NIXOS_MCP_TOKEN}";
            };
          };

          Pulumi = {
            url = "https://mcp.ai.pulumi.com/mcp";
            headers = {
              Authorization = "Bearer \${env:PULUMI_NIXOS_MCP_TOKEN}";
            };
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
            env = {
              SNYK_TOKEN = "\${env:SNYK_NIXOS_MCP_TOKEN}";
            };
            startup_timeout_sec = 300;
          };
        };
      };
    };
}
