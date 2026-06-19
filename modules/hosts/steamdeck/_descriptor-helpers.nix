{ lib, ... }:
let
  mkHostHomeModuleName =
    name:
    let
      first = builtins.substring 0 1 name;
      rest = builtins.substring 1 (builtins.stringLength name - 1) name;
    in
    "${lib.toLower first}${rest}HostHome";
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
      homeModuleName ? mkHostHomeModuleName name,
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
