{ inputs, ... }:
{
  imports = [
    # Import private syncthing configuration for device/folder definitions
    "${inputs.nix-secrets}/modules/sam-syncthing-private.nix"
  ];

  # Enable server-mode syncthing
  my.syncthing.enable = true;
  my.syncthing.serverUser = "sam";
}