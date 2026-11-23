{ lib, pkgs }:
{
  environment.systemPackages = [
    pkgs.synergy
  ];
  networking = {
    firewall = {
      allowedTCPPorts = [
        24800 # Synergy
      ];
      allowedUDPPorts = [
        24800 # Synergy
      ];
    };
  };
  services.xserver = {
    # Set US Qwerty as default for KDE Plasma (for Synergy compatibility)
    xkb = {
      layout = lib.mkDefault "us";
      variant = lib.mkDefault "";
    };
  };
}
