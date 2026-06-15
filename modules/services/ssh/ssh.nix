{
  flake.modules.nixos.ssh =
    { lib, ... }:
    {
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
