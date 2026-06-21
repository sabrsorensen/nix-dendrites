{
  lib,
  ...
}:
{ config, ... }:
let
  sshKeyHelpers = import ../../../../_ssh-key-helpers.nix { inherit config; };
in
{
  users.users.nix-remote = lib.mkIf config.my.host.deploy.enableRemoteUser {
    openssh.authorizedKeys.keyFiles = sshKeyHelpers.mkBuildSecretSshKeyFiles [
      "kamino/atlas_nix"
      "zaphodbeeblebrox/atlas_nix"
    ];
  };
}
