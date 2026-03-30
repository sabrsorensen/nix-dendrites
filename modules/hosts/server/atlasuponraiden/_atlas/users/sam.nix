{
  config,
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
  };
}
