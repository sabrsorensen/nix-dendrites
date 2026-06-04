{
  flake.modules.nixos.ssh =
    { lib, ... }:
    {
      services.openssh = {
        enable = true;
        openFirewall = true;
        allowSFTP = lib.mkDefault false;
        settings = {
          PasswordAuthentication = true;
          PermitRootLogin = "no";
        };
      };
      programs.ssh.startAgent = true;
    };
}
