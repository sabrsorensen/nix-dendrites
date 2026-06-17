{ inputs, ... }:
{
  imports = [
    inputs.self.modules.nixos.sam-syncthing
  ];

  # Enable server-mode syncthing for AtlasUponRaiden
  my.syncthing.enable = true;
}
