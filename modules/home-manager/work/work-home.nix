{
  inputs,
  ...
}:
{
  flake.modules.homeManager."work-home" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      dotnetCombined = pkgs.dotnetCorePackages.combinePackages [
        pkgs.dotnetCorePackages.sdk_6_0-bin
        pkgs.dotnetCorePackages.sdk_7_0-bin
        pkgs.dotnetCorePackages.sdk_8_0-bin
        pkgs.dotnetCorePackages.sdk_9_0-bin
        pkgs.dotnetCorePackages.sdk_10_0-bin
        pkgs.dotnetCorePackages.sdk_11_0-bin
      ];
      azureDevOpsExtension =
        if pkgs ? azure-cli && pkgs.azure-cli ? extensions && pkgs.azure-cli.extensions ? azure-devops then
          pkgs.azure-cli.extensions.azure-devops.overrideAttrs (old: {
            propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ pkgs.python3Packages.keyring ];
          })
        else
          null;
      azureCliWithDevOps =
        if pkgs ? azure-cli && azureDevOpsExtension != null then
          pkgs.azure-cli.withExtensions [ azureDevOpsExtension ]
        else if pkgs ? azure-cli then
          pkgs.azure-cli
        else
          null;
      nugetConfigDir = "${config.home.homeDirectory}/.nuget/NuGet";
      nugetConfigPath = "${nugetConfigDir}/NuGet.Config";
      hasNuGetSecrets =
        config.sops.secrets ? nuget_higi_source_url
        && config.sops.secrets ? nuget_higi_username
        && config.sops.secrets ? nuget_higi_token;
    in
    {
      imports = (
        with inputs.self.modules.homeManager;
        [
          home
          sam-home-base
          sam-home-work-private
          sam-work-secrets
          vscode
          mcp
          mcp-work
          codex
        ]
      );

      my.vscode = {
        installLocalDotnetSdk = lib.mkDefault true;
        profiles = {
          higiLlp = lib.mkDefault true;
          python = lib.mkDefault true;
          stm32 = lib.mkDefault true;
        };
      };

      home.packages =
        with pkgs;
        lib.filter (pkg: pkg != null) [
          git
          dotnetCombined
          azureCliWithDevOps
          (if pkgs ? pulumi then pulumi else null)
          (if pkgs ? uv then uv else null)
          (if pkgs ? nodejs then nodejs else null)
        ];

      sops.templates.nuget-higi-config = lib.mkIf hasNuGetSecrets {
        path = nugetConfigPath;
        mode = "0600";
        content = ''
          <?xml version="1.0" encoding="utf-8"?>
          <configuration>
            <packageSources>
              <clear />
              <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
              <add key="higi" value="${config.sops.placeholder.nuget_higi_source_url}" />
            </packageSources>
            <packageSourceCredentials>
              <higi>
                <add key="Username" value="${config.sops.placeholder.nuget_higi_username}" />
                <add key="ClearTextPassword" value="${config.sops.placeholder.nuget_higi_token}" />
              </higi>
            </packageSourceCredentials>
          </configuration>
        '';
      };
    };
}
