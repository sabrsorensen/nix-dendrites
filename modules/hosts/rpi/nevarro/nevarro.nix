{
  inputs,
  lib,
  ...
}:
let
  rpi = inputs.self.lib.rpi;
in
{
  flake.modules.nixos.Nevarro =
    {
      config,
      pkgs,
      ...
    }:
    let
      enableNixRemote =
        !(config.wsl.enable or false) && config ? sops && config.sops.secrets ? hashed_password;
    in
    {
      imports = [
        (rpi.mkBaseModule "Nevarro")
        inputs.self.modules.nixos.caddy
        inputs.self.modules.nixos.adguardhome
        inputs.self.modules.nixos.netbird
        inputs.self.modules.nixos.powerdns
      ];

      networking = {
        hostName = "Nevarro";
        useDHCP = false;
        interfaces.end0 = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = rpi.network.nevarro;
              prefixLength = 24;
            }
          ];
        };
        nameservers = [
          rpi.network.naboo
          "1.1.1.1"
          "9.9.9.9"
        ];
      };

      users.users.sam.openssh.authorizedKeys.keyFiles = [
        "${inputs.nix-secrets}/ssh-keys/atlas_nevarro.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino_nevarro.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphod_nevarro.pub"
      ];

      users.users.nix-remote = lib.mkIf enableNixRemote {
        openssh.authorizedKeys.keyFiles = [
          "${inputs.nix-secrets}/ssh-keys/atlas_nevarro_nix.pub"
          "${inputs.nix-secrets}/ssh-keys/kamino_nevarro_nix.pub"
          "${inputs.nix-secrets}/ssh-keys/zaphod_nevarro_nix.pub"
        ];
      };

      services.adguardhome.settings.dhcp.enabled = true;
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Nevarro";
}
