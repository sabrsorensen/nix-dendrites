{
  inputs,
  ...
}:
{

  flake.modules.nixos.secrets-base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      nix.settings.extra-substituters = [ "https://cache.thalheim.io" ];
      nix.settings.extra-trusted-public-keys = [
        "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
      ];

      environment.systemPackages = [
        pkgs.age
        pkgs.sops
        pkgs.ssh-to-age
      ];

      sops = {
        defaultSopsFormat = "yaml";
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      };
    };

  flake.modules.homeManager.secrets-base =
    { config, pkgs, ... }:
    let
      sopsKeyPath = "${config.home.homeDirectory}/.ssh/sops_ed25519";
    in
    {
      imports = [
        inputs.sops-nix.homeManagerModules.sops
      ];
      home.sessionVariables = {
        SOPS_AGE_KEY_CMD = "${pkgs.ssh-to-age}/bin/ssh-to-age -private-key < ${sopsKeyPath}";
      };
      sops = {
        age.sshKeyPaths = [ sopsKeyPath ];
      };
    };

}
