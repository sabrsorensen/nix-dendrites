{
  inputs,
  lib,
}:
{
  home-manager.users.sam = {
    imports = [
      inputs.self.modules.homeManager.AtlasUponRaiden
    ];
    # Force disable Home Manager syncthing to avoid conflicts with NixOS service
    my.syncthing.enable = lib.mkForce false;
  };
}