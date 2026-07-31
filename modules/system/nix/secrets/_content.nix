{ inputs, ... }:
{
  flake.modules.nixos.secrets-base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];
      nix.settings = {
        extra-substituters = [ "https://cache.thalheim.io" ];
        extra-trusted-public-keys = [ "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc=" ];
      };
      environment.systemPackages = [
        pkgs.age
        pkgs.sops
        pkgs.ssh-to-age
      ];
      sops = {
        defaultSopsFormat = "yaml";
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        # This personal-registry credential belongs only to the two services
        # that consume it.  Defining it unconditionally made WSL try to
        # decrypt the unrelated personal secrets file during activation.
        secrets.ghcr_token = lib.mkIf (config.my.host.services.arrSync || config.my.host.services.plex) {
          owner = "root";
          group = "root";
          mode = "0400";
          sopsFile = "${inputs.nix-secrets}/secrets.yaml";
        };
        secrets.github_nixos_token = lib.mkIf (config.my.host.platform != "wsl") {
          owner = "sam";
          group = "sam";
          mode = "0400";
          sopsFile = "${inputs.nix-secrets}/secrets.yaml";
        };
      };
    };
}
