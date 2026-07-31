{ lib, pkgs }:
{
  environment.systemPackages = with pkgs; [
    deskflow
  ];
  networking = {
    firewall = {
      allowedTCPPorts = [
        24800 # Deskflow
      ];
      allowedUDPPorts = [
        24800 # Deskflow
      ];
    };
  };
  services.xserver = {
    # Set US Qwerty as default for KDE Plasma (for Deskflow compatibility)
    xkb = {
      layout = lib.mkDefault "us";
      variant = lib.mkDefault "";
    };
  };
}
