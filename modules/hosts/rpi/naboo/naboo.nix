{
  inputs,
  lib,
  ...
}:
let
  mkServiceHostModule = import ../_rpi/service-host.nix { inherit inputs lib; };
in
{
  flake.modules.nixos.Naboo = lib.mkMerge [
    (mkServiceHostModule {
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
        dhcp-coredns
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
    })
    {
      # Disable problematic sysctl setting from nixos-raspberrypi
      boot.kernel.sysctl = lib.mkForce {
        # Remove vm.mmap_rnd_bits entirely - this kernel doesn't support it
      };

      services.dhcp-coredns = {
        enable = true;
        interface = "end0";
        startKeaOnBoot = false;
        localDomainApexIp = inputs.self.lib.rpi.network.atlasuponraiden;
        upstreamServers = [
          "1.1.1.1"
          "9.9.9.9"
        ];
      };
    }
  ];

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Naboo";
}
