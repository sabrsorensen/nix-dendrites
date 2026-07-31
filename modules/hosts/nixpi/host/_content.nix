{ inputs }:
let
  imageModule =
    suffix:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix") ];
      sdImage = {
        compressImage = false;
        expandOnBoot = true;
      };
      image.baseName = lib.mkDefault "${config.networking.hostName}-${suffix}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
    };
in
{
  hostModule = {
    networking.hostName = "nixpi";
    my.host = {
      name = "NixPi";
      formFactor = "server";
      platform = "rpi";
      home.enable = true;
    };
  };
  imageModule = imageModule "nixos-image";
  bootstrapModule = {
    networking.hostName = "nixpi";
    my.host = {
      name = "NixPi";
      formFactor = "server";
      platform = "rpi";
      home.enable = false;
      tags = [ "bootstrap" ];
      bootstrap.finalConfigName = "nixpi";
    };
    users.users.sam = {
      isNormalUser = true;
      description = "Sam";
      group = "sam";
      extraGroups = [
        "wheel"
      ];
      openssh.authorizedKeys.keyFiles = [ "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/kamino.pub" ];
    };
    users.groups.sam = { };
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    virtualisation.docker.enable = false;
    virtualisation.podman.enable = false;
  };
  bootstrapImageModule = imageModule "bootstrap";
}
