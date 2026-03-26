{
  config,
  inputs,
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

  services = {
    displayManager = {
      autoLogin = {
        enable = true;
        user = "sam";
      };
    };
  };
}
