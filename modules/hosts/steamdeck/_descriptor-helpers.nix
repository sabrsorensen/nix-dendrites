{ ... }:
{
  mkSteamdeckDescriptor =
    {
      name,
      identityFile,
      nixIdentityFile,
      homeOutputName,
      platformHost,
      platformRegistration,
    }:
    {
      inherit name;
      user.ssh = {
        inherit identityFile nixIdentityFile;
      };
      home.outputName = homeOutputName;
      platform = {
        host = platformHost;
        registration = platformRegistration;
      };
    };
}
