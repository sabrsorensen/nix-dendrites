{ ... }:
{
  flake.modules.nixos.ssh =
    { config, lib, ... }:
    lib.mkIf (config.my.host.services.ssh || config.my.host.is.server || config.my.host.is.rpi) {
      services.openssh = {
        enable = true;
        openFirewall = true;
        allowSFTP = lib.mkDefault false;
        settings = {
          PasswordAuthentication = lib.mkDefault false;
          KbdInteractiveAuthentication = lib.mkDefault false;
          PermitRootLogin = "no";
        };
      };
      programs.ssh.startAgent = true;
    };
}
