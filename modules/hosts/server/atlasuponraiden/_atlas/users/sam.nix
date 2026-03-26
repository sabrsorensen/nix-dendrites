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
    openssh.authorizedKeys.keyFiles = [
      "${inputs.nix-secrets}/ssh-keys/zaphod_atlas.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphod_atlas_root.pub"
    ];
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
