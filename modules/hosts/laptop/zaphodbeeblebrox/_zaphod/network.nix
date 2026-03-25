{ self, lib, ... }:
{
  networking = {
    firewall = {
      allowedTCPPorts = [
        1400 # noson
        3400 # noson
      ];
      allowedUDPPorts = [
      ];
    };
    hostName = "ZaphodBeeblebrox";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };
}
