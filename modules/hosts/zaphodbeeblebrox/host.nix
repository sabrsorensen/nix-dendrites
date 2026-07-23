{ config, inputs, ... }:
{
  flake.nixosConfigurations.zaphodbeeblebrox = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      {
        networking.hostName = "ZaphodBeeblebrox";

        my.host = {
          name = "ZaphodBeeblebrox";
          formFactor = "laptop";
          roles = {
            workstation = true;
            desktop = true;
            builder = true;
          };
          features = {
            armory = true;
            gui = true;
            gdrive = true;
            personalMcp = true;
            vscode = true;
            firmware = true;
            nix-ld = true;
            bluetooth = true;
            docker = true;
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
