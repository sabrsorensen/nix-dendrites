{
  config,
  lib,
  pkgs,
  ...
}:
let
  composeSources = {
    aarch64-linux = {
      url = "https://github.com/docker/compose/releases/download/v5.7.1/docker-compose-linux-aarch64";
      hash = "sha256-8vSfkDJAiV+nZMDco6FFSLdUrZQm9rYJzK9V7Fo6oqU=";
    };
    x86_64-linux = {
      url = "https://github.com/docker/compose/releases/download/v5.7.1/docker-compose-linux-x86_64";
      hash = "sha256-r0JnIqivXegS/O4wzBw58GOfX3I8ut77JeXU2wVAZM8=";
    };
  };
  composeSource =
    composeSources.${pkgs.stdenv.hostPlatform.system}
      or (throw "Docker Compose has no WSL artifact for ${pkgs.stdenv.hostPlatform.system}");
  composePlugin = pkgs.runCommand "docker-compose-cli-plugin-5.7.1" {
    src = pkgs.fetchurl composeSource;
  } ''
    install -Dm755 "$src" "$out/lib/docker/cli-plugins/docker-compose"
  '';
  dotnetCombined = pkgs.dotnetCorePackages.combinePackages [
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
{
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
      SOPS_AGE_KEY_CMD = "${pkgs.ssh-to-age}/bin/ssh-to-age -private-key < ${config.home.homeDirectory}/.ssh/sops_ed25519";
    };
    file.".docker/cli-plugins/docker-compose".source =
      "${composePlugin}/lib/docker/cli-plugins/docker-compose";
    file.".nuget/plugins/netcore/CredentialProvider.Microsoft" = lib.mkIf (credentialPlugin != null) {
      source = credentialPlugin;
      recursive = true;
    };
  };
  warnings = [
    ''
      Docker Desktop's WSL Compose 5.6.1 cannot build VS Code dev containers
      when Buildx denies access to the generated Dockerfile outside the build
      context (docker/compose#14285). Compose fixed this in 5.7.0. This profile
      installs Compose 5.7.1 as a user CLI plugin until Docker Desktop bundles
      the fix. Recheck the Desktop-provided plugin with:
        /usr/local/lib/docker/cli-plugins/docker-compose version
      Remove the plugin override in
      modules/platforms/wsl/wsl-work-home/_wsl-work-home.nix once it reports
      5.7.0 or newer.
    ''
  ] ++ lib.optional (azureDevOpsExtension != null) ''
    azure-cli's azure-devops extension is overridden to propagate
    python3Packages.keyring, which the nixpkgs package omits. Remove the
    override in modules/platforms/wsl/wsl-work-home/_wsl-work-home.nix once
    nixpkgs adds it -- check with:
      nix eval .#nixosConfigurations.nixos-wsl.pkgs.azure-cli.extensions.azure-devops.propagatedBuildInputs \
        --apply 'map (p: p.pname or p.name)'
  '';
  sops.templates.nuget-higi-config = lib.mkIf (config.sops.secrets ? nuget_higi_source_url) {
    path = "${config.home.homeDirectory}/.nuget/NuGet/NuGet.Config";
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
}
