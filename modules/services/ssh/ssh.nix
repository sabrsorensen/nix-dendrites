{
  flake.modules.nixos.ssh =
    { config, lib, ... }:
    let
      autoEnable =
        config.my.host.is.server
        || config.my.host.is.rpi
        || config.my.host.deploy.canDeployRemotely
        || config.my.host.deploy.enableRemoteUser;
    in
    {
      options.my.services.ssh.enable = lib.mkEnableOption "OpenSSH server defaults";

      config = lib.mkIf (config.my.services.ssh.enable || autoEnable) {
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
    };
}
