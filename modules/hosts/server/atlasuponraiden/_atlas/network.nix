{ self, lib, ... }:
{
  services.netbirdProxy.turnForward = {
    enable = true;
    externalInterface = "eno1";
  };

  networking = {
    firewall = {
      allowedTCPPorts = [
        4470 # ankerctl
      ];
      allowedUDPPorts = [
        32100 # ankerctl
        32108 # ankerctl
      ];
    };
    hostName = "AtlasUponRaiden";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };
}
