{
  inputs,
  ...
}:
let
  defaultNixosImports = [ inputs.self.modules.nixos."sam-system-cli" ];
in
{
  mkSteamdeckDescriptor =
    {
      name,
      identityFile,
      nixIdentityFile,
      hostName,
      config,
      homeOutputName,
      homeConfigurationName ? "deck@${hostName}",
      homeModuleName ? homeOutputName,
      extraImports ? [ ],
      platformHost,
      platformRegistration,
    }:
    {
      inherit
        name
        hostName
        config
        ;
      user.ssh = {
        inherit identityFile nixIdentityFile;
      };
      nixos.imports = defaultNixosImports ++ extraImports;
      home = {
        outputName = homeOutputName;
        configurationName = homeConfigurationName;
        moduleName = homeModuleName;
      };
      platform = {
        host = platformHost;
        registration = platformRegistration;
      };
    };
}
