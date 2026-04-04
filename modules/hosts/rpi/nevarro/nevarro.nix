{
  inputs,
  lib,
  ...
}:
let
  mkServiceHostModule = import ../_rpi/service-host.nix { inherit inputs lib; };
in
{
  flake.modules.nixos.Nevarro = mkServiceHostModule {
    hostName = "Nevarro";
    address = inputs.self.lib.rpi.network.nevarro;
    nameservers = [
      inputs.self.lib.rpi.network.naboo
      "1.1.1.1"
      "9.9.9.9"
    ];
    serviceImports = with inputs.self.modules.nixos; [
      caddy
      adguardhome
      netbird
      powerdns
    ];
    samAuthorizedKeys = [
      "${inputs.nix-secrets}/ssh-keys/atlas_nevarro.pub"
      "${inputs.nix-secrets}/ssh-keys/kamino_nevarro.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphod_nevarro.pub"
    ];
    nixRemoteAuthorizedKeys = [
      "${inputs.nix-secrets}/ssh-keys/atlas_nevarro_nix.pub"
      "${inputs.nix-secrets}/ssh-keys/kamino_nevarro_nix.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphod_nevarro_nix.pub"
    ];
    adguardDhcpEnabled = true;
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Nevarro";
}
