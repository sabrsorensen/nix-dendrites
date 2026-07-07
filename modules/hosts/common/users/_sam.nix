{
  authorizedKeyPaths,
  autoLogin ? false,
  extraGroups ? [
    "dialout"
    "networkmanager"
    "users"
  ],
}:
{
  config,
  lib,
  ...
}:
let
  sshKeyHelpers = import ../_ssh.nix { inherit config; };
in
{
  users.users.sam = {
    inherit extraGroups;
    hashedPasswordFile = config.sops.secrets.hashed_password.path;
    openssh.authorizedKeys.keyFiles = lib.mkForce (
      sshKeyHelpers.mkBuildSecretSshKeyFiles authorizedKeyPaths
    );
  };

  services.displayManager.autoLogin = lib.mkIf autoLogin {
    enable = true;
    user = "sam";
  };
}
