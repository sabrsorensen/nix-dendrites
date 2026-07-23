{ config, inputs, ... }:
{
  flake.nixosConfigurations.kamino = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      {
        networking.hostName = "Kamino";

        my.host = {
          name = "Kamino";
          formFactor = "laptop";
          roles = {
            workstation = true;
            desktop = true;
            builder = true;
          };
          features = {
            gui = true;
            gdrive = true;
            personalMcp = true;
            vscode = true;
            firmware = true;
            nix-ld = true;
            docker = true;
            podman = true;
            bitwarden = true;
            deskflow = true;
            flatpak = true;
            minecraft = true;
            nvidia = true;
            noson = true;
            office = true;
            steam = true;
            threedprinter = true;
            wine = true;
            zsa = true;
          };
          services.ssh = true;
        };
        my.deployment = {
          enableRemoteUser = true;
          canDeployRemotely = true;
          sleepy = true;
          localFlakePath = "/home/sam/src/nix-dendrites";
        };
      }
    ];
  };
}
