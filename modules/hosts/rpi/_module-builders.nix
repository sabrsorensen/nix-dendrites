{
  inputs,
  lib,
}:
{
  mkBaseModule = hostName: {
    imports = [
      inputs.nixos-hardware.nixosModules.raspberry-pi-4
      {
        _module.args.nixos-raspberrypi = inputs.nixos-raspberrypi;
        imports = [
          inputs.nixos-raspberrypi.nixosModules.trusted-nix-caches
          inputs.nixos-raspberrypi.nixosModules.nixpkgs-rpi
        ];
      }
      inputs.self.modules.nixos.samCli
      inputs.self.modules.nixos.system-cli
      ./_rpi/base.nix
    ];

    virtualisation.docker.enable = lib.mkForce false;
    virtualisation.podman.enable = lib.mkForce false;

    networking.hostName = hostName;
  };

  mkStaticModule =
    {
      hostName,
      address,
      nameservers ? [ ],
      extraImports ? [ ],
      extraConfig ? { },
    }:
    {
      imports = extraImports ++ [ extraConfig ];

      networking = {
        inherit hostName nameservers;
        useDHCP = false;
        interfaces.end0 = {
          useDHCP = false;
          ipv4.addresses = [
            {
              inherit address;
              prefixLength = 24;
            }
          ];
        };
      };
    };

  mkImageModule =
    hostName:
    { config, pkgs, ... }:
    {
      imports = [
        (builtins.getAttr hostName inputs.self.modules.nixos)
        (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
      ];
      sdImage = {
        compressImage = false;
        expandOnBoot = true;
      };
      image.baseName = lib.mkDefault "${config.networking.hostName}-nixos-image-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
    };
}
