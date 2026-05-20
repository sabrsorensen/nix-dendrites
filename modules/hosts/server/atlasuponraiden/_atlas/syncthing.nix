{ inputs, ... }:
{
  imports = [
    # Universal syncthing config that works in both NixOS and Home Manager contexts
    "${inputs.nix-secrets}/modules/sam-syncthing-universal.nix"
  ];

  # Enable server-mode syncthing for AtlasUponRaiden
  my.syncthing.enable = true;
  my.syncthing.serverUser = "sam";
}