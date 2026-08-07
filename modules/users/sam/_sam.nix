{
  config,
  inputs,
  ...
}:
{
  sops.secrets.hashed_password = {
    owner = "root";
    group = "root";
    mode = "0400";
    neededForUsers = true;
    sopsFile = "${inputs.nix-secrets}/secrets.yaml";
  };

  users.groups.sam = { };

  users.users.sam = {
    isNormalUser = true;
    description = "Sam";
    group = "sam";
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets.hashed_password.path;
  };
}
