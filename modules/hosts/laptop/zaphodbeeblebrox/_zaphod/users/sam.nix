{
  inputs,
  ...
}:
{
  users.users.sam.extraGroups = [
    "dialout"
    "docker"
    "networkmanager"
    "users"
  ];

  services = {
    displayManager = {
      autoLogin = {
        enable = true;
        user = "sam";
      };
    };
  };
}
