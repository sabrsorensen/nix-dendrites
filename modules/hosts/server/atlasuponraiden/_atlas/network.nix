{ self, lib, ... }:
{
  networking = {
    firewall = {
      allowedTCPPorts = [
      ];
      allowedUDPPorts = [
      ];
    };
    hostName = "AtlasUponRaiden";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };
}
