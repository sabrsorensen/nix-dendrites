{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos."bootstrap-base" =
    { lib, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        system-minimal
        ssh
        cli-tools
        secrets-base
        inputs.self.modules.nixos."bootstrap-enroll"
      ];

      my.host = {
        lifecycle.mode = lib.mkDefault "bootstrap";
        bootstrap.enable = lib.mkDefault true;
        deploy = {
          enableRemoteUser = lib.mkDefault false;
          sleepy = lib.mkDefault false;
        };
      };

      my.services.ssh.enable = lib.mkDefault true;

      services.openssh.enable = lib.mkDefault true;
      services.openssh.settings = {
        PasswordAuthentication = lib.mkDefault true;
        KbdInteractiveAuthentication = lib.mkDefault false;
      };
    };
}
