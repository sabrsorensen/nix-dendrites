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
        blocky
        dhcp-coredns
      ];
      samAuthorizedKeyPaths = [
        "atlasuponraiden/naboo"
        "kamino/naboo"
        "zaphodbeeblebrox/naboo"
      ];
      nixRemoteAuthorizedKeyPaths = [
        "atlasuponraiden/naboo_nix"
        "kamino/naboo_nix"
        "zaphodbeeblebrox/naboo_nix"
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
        startKeaOnBoot = false;
        localDomainApexIp = inputs.self.lib.rpi.network.atlasuponraiden;
        upstreamServers = [
          "1.1.1.1"
          "9.9.9.9"
        ];
        staticRecords = staticDnsRecords;
        failover = {
          enable = true;
          peerName = "Nevarro";
          peerIp = inputs.self.lib.rpi.network.nevarro;
          probeDomains = [
            "naboo"
            "nevarro"
            "atlasuponraiden"
          ];
        };
      };
    }
  ];

  flake.lib.hostInventory.Naboo = inputs.self.lib.mkInventoryHost {
    ssh = inputs.self.lib.mkInventorySsh {
      base = inputs.self.lib.mkInventorySshBase {
        user = primaryInteractiveUser;
        identityFile = "~/.ssh/naboo_id_ed25519";
      };
      nix = inputs.self.lib.mkInventorySshNix {
        identityFile = "~/.ssh/nix_naboo_id_ed25519";
      };
    };
    serviceRoles = [
      "blocky-dns"
      "dhcp-standby"
    ];
    deploy = inputs.self.lib.mkInventoryDeploy {
      remoteMethod = "secure";
      secure = inputs.self.lib.mkInventorySecureDeploy {
        peerName = "Nevarro";
        peerIp = inputs.self.lib.rpi.network.nevarro;
        probeDomains = inputs.self.lib.localDns.secureDeployProbeDomains;
      };
    };
    outputs =
      inputs.self.lib.mkNixosOutputs {
        system = "aarch64-linux";
        name = "naboo";
        configuration = "Naboo";
      }
      ++ inputs.self.lib.mkNixosOutputs {
        system = "aarch64-linux";
        name = "naboo-image";
        configuration = "NabooImage";
        buildProduct = "sdImage";
      };
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Naboo";
}
