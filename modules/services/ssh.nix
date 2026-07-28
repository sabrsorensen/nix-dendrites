{ ... }:
{
  flake.modules.nixos.ssh =
    { config, lib, ... }:
    lib.mkIf (config.my.host.services.ssh || config.my.host.is.server || config.my.host.is.rpi) {
      services.openssh = {
        enable = true;
        openFirewall = true;
        # Atlas is the deployment and remote-build endpoint.  The other SSH
        # hosts expose only their normal shell service.
        allowSFTP = lib.mkDefault (config.my.host.name == "AtlasUponRaiden");
        settings = {
          PasswordAuthentication = lib.mkDefault false;
          KbdInteractiveAuthentication = lib.mkDefault false;
          PermitRootLogin = "no";
        };
      };
      programs.ssh.startAgent = true;
    };
}
