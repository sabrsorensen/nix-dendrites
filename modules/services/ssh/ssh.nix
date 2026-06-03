{
  flake.modules.nixos.ssh =
    {
      config,
      ...
    }:
    {
      services.openssh = {
        enable = true;
        openFirewall = true;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = true;
          PermitRootLogin = "no";
        };
        allowSFTP = true;
      };
      networking.firewall.allowedTCPPorts = config.services.openssh.ports;
      programs.ssh.startAgent = true;
    };
}
