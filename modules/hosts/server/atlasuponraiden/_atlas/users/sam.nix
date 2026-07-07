(import ../../../../common/users/_sam.nix {
  extraGroups = [
    "dialout"
    "docker"
    "networkmanager"
    "users"
  ];
  authorizedKeyPaths = [
    "kamino/atlas"
    "no-phone/atlas"
    "zaphodbeeblebrox/atlas"
  ];
})
