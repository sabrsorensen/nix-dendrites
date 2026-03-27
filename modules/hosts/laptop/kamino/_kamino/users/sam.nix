{ config, ... }:
{
  users.users.sam.extraGroups = [
    "dialout"
    "networkmanager"
    "users"
  ];
  users.users.sam.hashedPasswordFile = config.sops.secrets.hashed_password.path;

  services.displayManager.autoLogin = {
    enable = true;
    user = "sam";
  };
}
