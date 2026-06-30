{
  config,
  lib,
  ...
}:
{
  #services.netbirdProxy.turnForward = {
  #  enable = true;
  #  externalInterface = "eno1";
  #};

  networking = {
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };

  my.host.address = config.systemConstants.network.atlasuponraiden;
}
