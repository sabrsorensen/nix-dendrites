{
  users.users.sam.extraGroups = [
    "dialout"
    "docker"
    "networkmanager"
    "users"
  ];

  home-manager.users.sam = { };

  services = {
    displayManager = {
      autoLogin = {
        enable = true;
        user = "sam";
      };
    };
  };
}
