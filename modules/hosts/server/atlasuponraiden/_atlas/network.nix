{ self, lib, ... }:
{
  networking = {
    firewall = {
      allowedTCPPorts = [
        4470 # ankerctl
        8384 # syncthing GUI
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
