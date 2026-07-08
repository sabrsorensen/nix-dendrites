{
  inputs,
  ...
}:
{
  flake.modules.homeManager."sam-home-work" =
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
      azureArtifactsCredentialProvider =
        if pkgs ? azure-artifacts-credprovider then pkgs.azure-artifacts-credprovider else null;
      azureArtifactsCredentialProviderNuGetPlugin =
        if azureArtifactsCredentialProvider != null then
          pkgs.runCommand "azure-artifacts-credprovider-nuget-plugin" { } ''
            mkdir -p "$out"
            cp -rs ${azureArtifactsCredentialProvider}/lib/azure-artifacts-credprovider/. "$out/"
            rm "$out/CredentialProvider.Microsoft"
            ln -s ${azureArtifactsCredentialProvider}/bin/CredentialProvider.Microsoft "$out/CredentialProvider.Microsoft"
          ''
        else
          null;
      nugetConfigDir = "${config.home.homeDirectory}/.nuget/NuGet";
      nugetConfigPath = "${nugetConfigDir}/NuGet.Config";
      nugetPluginDir = "${config.home.homeDirectory}/.nuget/plugins/netcore/CredentialProvider.Microsoft";
      hasNuGetSourceUrl = config.sops.secrets ? nuget_higi_source_url;
    in
    {
      imports = (
        with inputs.self.modules.homeManager;
        [
          home
          sam-home-base
          mcp-work
          codex
          "${inputs.nix-work-secrets}/modules/sam-secrets-private.nix"
        ]
      );

      config = lib.mkIf config.my.host.is.wsl {
        my = {
          buildSecretRoot = lib.mkForce inputs.nix-work-secrets;
          gitSecretRoot = lib.mkForce inputs.nix-work-secrets;
          gpgKeysDir = lib.mkForce "${inputs.nix-work-secrets}/gpg-keys";
        };

        my.editor = {
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
            azureArtifactsCredentialProvider
            (if pkgs ? pulumi then pulumi else null)
            (if pkgs ? uv then uv else null)
            (if pkgs ? nodejs then nodejs else null)
          ];

        home.file.${nugetPluginDir} = lib.mkIf (azureArtifactsCredentialProvider != null) {
          source = azureArtifactsCredentialProviderNuGetPlugin;
          recursive = true;
        };

        sops.templates.nuget-higi-config = lib.mkIf hasNuGetSourceUrl {
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
            </configuration>
          '';
        };
      };
    };
}
