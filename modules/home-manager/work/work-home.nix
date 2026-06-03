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
      nugetConfigDir = "${config.home.homeDirectory}/.nuget/NuGet";
      nugetConfigPath = "${nugetConfigDir}/NuGet.Config";
    in
    {
      imports =
        (with inputs.self.modules.homeManager; [
          home
          sam-git
          sam-work-secrets
          vscode
          mcp
          mcp-work
          codex
        ])
        ++ [
          "${inputs.nix-work-secrets}/modules/sam-secrets-private.nix"
        ];

      my.vscode = {
        installLocalDotnetSdk = lib.mkDefault true;
        profiles = {
          higiLlp = lib.mkDefault true;
          python = lib.mkDefault true;
          stm32 = lib.mkDefault true;
        };
      };

      home.username = lib.mkDefault "sam";
      home.homeDirectory = lib.mkDefault "/home/sam";

      home.packages =
        with pkgs;
        lib.filter (pkg: pkg != null) [
          git
          dotnetCombined
          (if pkgs ? azure-cli then azure-cli else null)
          (if pkgs ? pulumi then pulumi else null)
          (if pkgs ? spec-kit then spec-kit else null)
          (
            if pkgs ? uv then
              uv
            else if pkgs ? unstable && pkgs.unstable ? uv then
              pkgs.unstable.uv
            else
              null
          )
          (if pkgs ? nodejs then nodejs else null)
        ];

      home.activation.configureNuGet = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                if [ -e "${config.sops.secrets.nuget_higi_source_url.path}" ] \
                  && [ -e "${config.sops.secrets.nuget_higi_username.path}" ] \
                  && [ -e "${config.sops.secrets.nuget_higi_token.path}" ]; then
                  run install -d -m 700 "${nugetConfigDir}"
                  run /bin/sh -c 'cat > "$1" <<EOF
        <?xml version="1.0" encoding="utf-8"?>
        <configuration>
          <packageSources>
            <clear />
            <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
            <add key="higi" value="$(cat ${config.sops.secrets.nuget_higi_source_url.path})" />
          </packageSources>
          <packageSourceCredentials>
            <higi>
              <add key="Username" value="$(cat ${config.sops.secrets.nuget_higi_username.path})" />
              <add key="ClearTextPassword" value="$(cat ${config.sops.secrets.nuget_higi_token.path})" />
            </higi>
          </packageSourceCredentials>
        </configuration>
        EOF
        ' _ "${nugetConfigPath}"
                  run chmod 600 "${nugetConfigPath}"
                fi
      '';
    };
}
