{
  config,
  lib,
  pkgs,
  ...
}:
let
  network = config.systemConstants.network;
in
{
  imports = [ ./hardware.nix ];

  environment.systemPackages = with pkgs; [
    libraspberrypi
    wget
  ];

  programs.command-not-found.enable = false;
  programs.nix-index.enable = false;

  security.pam.services.sshd.updateWtmp = true;

  networking.defaultGateway = {
    address = network.gateway;
    interface = "end0";
  };

  boot.kernelParams = [ "cma=64M" ];
}
