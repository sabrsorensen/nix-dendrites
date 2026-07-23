{ inputs, ... }:
{
  flake.modules.nixos.impermanence =
    { config, lib, ... }:
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      config = lib.mkIf config.my.host.features.impermanence {
        environment.persistence."/persistent" = {
          hideMounts = true;
          directories = [
            "/var/log"
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
            "/etc/NetworkManager/system-connections"
          ];
          files = [ "/etc/machine-id" ];
        };
        home-manager.sharedModules = [
          {
            home.persistence."/persistent" = { };
          }
        ];
        programs.fuse.userAllowOther = true;
      };
    };
}
