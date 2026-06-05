{
  inputs,
  lib,
  ...
}:
let
  primaryInteractiveUser = "sam";
  mkServiceHostModule = import ../_rpi/service-host.nix { inherit inputs lib; };
  staticDnsRecords = inputs.self.lib.localDns.staticRecords;
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
        blocky
        dhcp-coredns
        #netbird-server
      ];
      samAuthorizedKeys = [
        "${inputs.nix-secrets}/ssh-keys/atlas/nevarro.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino/nevarro.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/nevarro.pub"
      ];
      nixRemoteAuthorizedKeys = [
        "${inputs.nix-secrets}/ssh-keys/atlas/nevarro_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino/nevarro_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/nevarro_nix.pub"
      ];
    })
    {
      # Disable problematic sysctl setting from nixos-raspberrypi
      boot.kernel.sysctl = lib.mkForce {
        # Remove vm.mmap_rnd_bits entirely - this kernel doesn't support it
      };

      my.host = {
        inherit primaryInteractiveUser;
        roles = {
          rpi = true;
          serviceHost = true;
        };
      };

      services.dhcp-coredns = {
        enable = true;
        interface = "end0";
        localDomainApexIp = inputs.self.lib.rpi.network.atlasuponraiden;
        upstreamServers = [
          "1.1.1.1"
          "9.9.9.9"
        ];
        staticRecords = staticDnsRecords;
      };
    }
  ];

  flake.lib.hostInventory.Nevarro = inputs.self.lib.mkInventoryHost {
    ssh = inputs.self.lib.mkInventorySsh {
      base = inputs.self.lib.mkInventorySshBase {
        user = primaryInteractiveUser;
        identityFile = "~/.ssh/nevarro_id_ed25519";
      };
      nix = inputs.self.lib.mkInventorySshNix {
        identityFile = "~/.ssh/nix_nevarro_id_ed25519";
      };
    };
    serviceRoles = [
      "blocky-dns"
      "dhcp-primary"
    ];
    deploy = inputs.self.lib.mkInventoryDeploy {
      remoteMethod = "secure";
      secure = inputs.self.lib.mkInventorySecureDeploy {
        peerName = "Naboo";
        peerIp = inputs.self.lib.rpi.network.naboo;
        probeDomains = inputs.self.lib.localDns.secureDeployProbeDomains;
      };
    };
    outputs =
      inputs.self.lib.mkNixosOutputs {
        system = "aarch64-linux";
        name = "nevarro";
        configuration = "Nevarro";
      }
      ++ inputs.self.lib.mkNixosOutputs {
        system = "aarch64-linux";
        name = "nevarro-image";
        configuration = "NevarroImage";
        buildProduct = "sdImage";
      };
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Nevarro";
}
