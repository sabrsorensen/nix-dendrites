{ inputs, ... }:
{
  # The private work input supplies the SOPS secret declarations.  This module
  # owns only the portable WSL work tooling and is safe on every other host.
  flake.modules.nixos.wsl-work-home =
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
      dotnetRoot = "${dotnetCombined}/share/dotnet";
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
      credentialProvider =
        if pkgs ? azure-artifacts-credprovider then pkgs.azure-artifacts-credprovider else null;
      credentialPlugin =
        if credentialProvider != null then
          pkgs.runCommand "azure-artifacts-credprovider-nuget-plugin" { } ''
            mkdir -p "$out"
            cp -rs ${credentialProvider}/lib/azure-artifacts-credprovider/. "$out/"
            rm "$out/CredentialProvider.Microsoft"
            ln -s ${credentialProvider}/bin/CredentialProvider.Microsoft "$out/CredentialProvider.Microsoft"
          ''
        else
          null;
    in
    lib.mkIf config.my.host.roles.wsl {
      # Required by the retained multi-SDK work toolchain.  Keep this narrow
      # and host-gated rather than relaxing package policy globally.
      nixpkgs.config.permittedInsecurePackages = [
        "dotnet-sdk-6.0.428"
        "dotnet-sdk-7.0.410"
      ];

      home-manager.users.ssorensen = {
        home = {
          packages = lib.filter (pkg: pkg != null) [
            pkgs.git
            dotnetCombined
            azureCliWithDevOps
            credentialProvider
            (if pkgs ? pulumi then pkgs.pulumi else null)
            (if pkgs ? uv then pkgs.uv else null)
            (if pkgs ? nodejs then pkgs.nodejs else null)
          ];
          sessionVariables = {
            DOTNET_ROOT = dotnetRoot;
            DOTNET_ROOT_X64 = dotnetRoot;
            DOTNET_SDK_VULNERABILITY_CHECK_DISABLE = "true";
          };
          file.".nuget/plugins/netcore/CredentialProvider.Microsoft" = lib.mkIf (credentialPlugin != null) {
            source = credentialPlugin;
            recursive = true;
          };
        };

        # This is a Home Manager secret declaration, not a system SOPS
        # secret.  Checking the system namespace silently omitted the
        # predecessor's NuGet template on WSL.
        sops.templates.nuget-higi-config =
          lib.mkIf (config.home-manager.users.ssorensen.sops.secrets ? nuget_higi_source_url)
            {
              path = "/home/ssorensen/.nuget/NuGet/NuGet.Config";
              mode = "0600";
              content = ''
                <?xml version="1.0" encoding="utf-8"?>
                <configuration>
                  <packageSources>
                    <clear />
                    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
                    <add key="higi" value="${config.home-manager.users.ssorensen.sops.placeholder.nuget_higi_source_url}" />
                  </packageSources>
                </configuration>
              '';
            };
      };
    };
}
