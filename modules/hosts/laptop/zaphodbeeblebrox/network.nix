{ self, lib, ... }:
{
  flake.modules.nixos.homeserver = {
    networking = {
      firewall = {
        allowedTCPPorts = [
          1400 3400 # noson
        ];
        allowedUDPPorts = [
        ];
      };
      hostName = "ZaphodBeeblebrox";
      networkmanager.enable = true;
      useDHCP = lib.mkDefault true;
    };
  };
}
