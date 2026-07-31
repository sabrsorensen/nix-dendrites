{
  networking.hostName = "NixOS-WSL";
  my.host = {
    name = "NixOS-WSL";
    formFactor = "vm";
    platform = "wsl";
    home.enable = true;
    # WSL is a work machine and remains a workstation for shared local
    # tooling and workstation-scoped policy such as printer discovery.
    roles = {
      workstation = true;
    };
    features.nix-ld = true;
  };
  my.deployment = {
    # Declare the checkout explicitly so `nh` and local helpers use the
    # intended repository path.
    localFlakePath = "/home/ssorensen/src/nix-dendrites";
  };
}
