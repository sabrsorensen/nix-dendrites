{
  inputs,
  ...
}:
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
      nixosProfileNames ? [ ],
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
      nixos.imports =
        extraImports ++ map (profileName: inputs.self.modules.nixos.${profileName}) nixosProfileNames;
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
