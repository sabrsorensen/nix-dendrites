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
// import ./identity.nix { inherit inputs; }
// import ./packages.nix
// import ./runtime.nix
// import ./variants.nix
