{
  inputs,
  lib,
  ...
}:
let
  mkServiceHostModule = import ../_rpi/service-host.nix { inherit inputs lib; };
in
{
  flake.modules.nixos.Nevarro = lib.mkMerge [
    (mkServiceHostModule {
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
        netbird-server
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
    })
    {
      # Disable problematic sysctl setting from nixos-raspberrypi
      boot.kernel.sysctl = lib.mkForce {
        # Remove vm.mmap_rnd_bits entirely - this kernel doesn't support it
      };
    }
  ];

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Nevarro";
}
