{
  config,
  lib,
  ...
}:
let
  sshKeyHelpers = import ../../../../_ssh-key-helpers.nix { inherit config; };
in
{
  users.users.sam = {
    extraGroups = [
      "dialout"
      "docker"
      "networkmanager"
      "users"
    ];
    hashedPasswordFile = config.sops.secrets.hashed_password.path;
    openssh.authorizedKeys.keyFiles = lib.mkForce (
      sshKeyHelpers.mkBuildSecretSshKeyFiles [
        "kamino/atlas"
        "no-phone/atlas"
        "zaphodbeeblebrox/atlas"
      ]
    );
  };
}
