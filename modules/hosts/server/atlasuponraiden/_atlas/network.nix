{ self, lib, ... }:
{
  networking = {
    firewall = {
      allowedTCPPorts = [
        8384 # syncthing GUI
      ];
      allowedUDPPorts = [
      ];
    };
    hostName = "AtlasUponRaiden";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };
}
