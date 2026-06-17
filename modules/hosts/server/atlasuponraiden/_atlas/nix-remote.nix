{
  inputs,
  lib,
  ...
}:
{ config, ... }:
{
  users.users.nix-remote = lib.mkIf config.my.host.deploy.enableRemoteUser {
    openssh.authorizedKeys.keyFiles = inputs.self.lib.shared.mkSecretsSshKeyFiles [
      "kamino/atlas_nix"
      "zaphodbeeblebrox/atlas_nix"
    ];
  };
}
