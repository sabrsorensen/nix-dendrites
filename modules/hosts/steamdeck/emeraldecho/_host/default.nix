{
  inputs,
  ...
}:
let
  root = ../../../..;
in
{
  inherit root;
  context = {
    primaryInteractiveUser = "sam";
    roles.steamdeck = true;
    deploy = {
      canDeployRemotely = false;
      sleepy = true;
    };
    ssh.enableNixBlocks = false;
    syncthing = {
      mode = "home";
      hasTray = false;
    };
  };
}
#
# The optional imports below are host escape hatches for SteamOS-specific
# compatibility work. Keep them separate from the inventory metadata above so it
# stays obvious which parts are declarative fleet state and which parts exist to
# bridge an unmanaged base OS.
// import ./identity.nix { inherit inputs; }
// import ./packages.nix
// import ./runtime.nix
// import ./variants.nix
