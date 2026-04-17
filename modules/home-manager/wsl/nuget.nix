{
  flake.modules.homeManager.nuget =
    {
      config,
      lib,
      ...
    }:
    let
      nugetConfigDir = "${config.home.homeDirectory}/.nuget/NuGet";
      nugetConfigPath = "${nugetConfigDir}/NuGet.Config";
    in
    {
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
