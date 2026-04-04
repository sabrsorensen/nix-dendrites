{
  inputs,
  lib,
  ...
}:
let
  mkServiceHostModule = import ../_rpi/service-host.nix { inherit inputs lib; };
in
{
  flake.modules.nixos.Naboo = mkServiceHostModule {
    hostName = "Naboo";
    address = inputs.self.lib.rpi.network.naboo;
    nameservers = [
      inputs.self.lib.rpi.network.nevarro
      "1.1.1.1"
      "9.9.9.9"
    ];
    serviceImports = with inputs.self.modules.nixos; [
      caddy
      adguardhome
      powerdns
    ];
    samAuthorizedKeys = [
      "${inputs.nix-secrets}/ssh-keys/atlas_naboo.pub"
      "${inputs.nix-secrets}/ssh-keys/kamino_naboo.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphod_naboo.pub"
    ];
    nixRemoteAuthorizedKeys = [
      "${inputs.nix-secrets}/ssh-keys/atlas_naboo_nix.pub"
      "${inputs.nix-secrets}/ssh-keys/kamino_naboo_nix.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphod_naboo_nix.pub"
    ];
    adguardDhcpEnabled = false;
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Naboo";
}
