{
  config,
  lib,
  ...
}:
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
      map (keyPath: "${config.my.buildSecretRoot}/ssh-keys/${keyPath}.pub") [
        "kamino/atlas"
        "zaphodbeeblebrox/atlas"
      ]
    );
  };
}
