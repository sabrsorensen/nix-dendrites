{
  networking = {
    hostName = "Kamino";
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ 25565 ]; # Minecraft
  };
}
