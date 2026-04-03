{
  inputs,
  lib,
  ...
}:
let
  rpi = inputs.self.lib.rpi;
in
{
  flake.modules.nixos.Naboo =
    {
      config,
      pkgs,
      ...
    }:
    let
      enableNixRemote = !(config.wsl.enable or false) && config ? sops && config.sops.secrets ? hashed_password;
    in
    {
      imports = [
        (rpi.mkBaseModule "Naboo")
        inputs.self.modules.nixos.caddy
        inputs.self.modules.nixos.adguardhome
        inputs.self.modules.nixos.powerdns
      ];

      networking = {
        hostName = "Naboo";
        useDHCP = false;
        interfaces.end0 = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = rpi.network.naboo;
              prefixLength = 24;
            }
          ];
        };
        nameservers = [
          rpi.network.nevarro
          "1.1.1.1"
          "9.9.9.9"
        ];
      };

      users.users.sam.openssh.authorizedKeys.keyFiles = [
        "${inputs.nix-secrets}/ssh-keys/atlas_naboo.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino_naboo.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphod_naboo.pub"
      ];

      users.users.nix-remote = lib.mkIf enableNixRemote {
        openssh.authorizedKeys.keyFiles = [
          "${inputs.nix-secrets}/ssh-keys/atlas_naboo_nix.pub"
          "${inputs.nix-secrets}/ssh-keys/kamino_naboo_nix.pub"
          "${inputs.nix-secrets}/ssh-keys/zaphod_naboo_nix.pub"
        ];
      };

      services.adguardhome.settings.dhcp.enabled = false;
    };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Naboo";
}
