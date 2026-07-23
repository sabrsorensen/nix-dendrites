{ inputs, ... }:
{
  flake.modules.nixos.users-zaphodbeeblebrox =
    { config, lib, ... }:
    lib.mkIf (config.my.host.name == "ZaphodBeeblebrox") {
      sops.secrets.hashed_password = {
        owner = "root";
        group = "root";
        mode = "0400";
        neededForUsers = true;
        sopsFile = "${inputs.nix-secrets}/secrets.yaml";
      };
      users.users.sam = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "dialout"
          "docker"
          "networkmanager"
          "users"
        ];
        hashedPasswordFile = config.sops.secrets.hashed_password.path;
        openssh.authorizedKeys.keyFiles = [ "${inputs.nix-secrets}/ssh-keys/kamino/zaphod.pub" ];
      };
      services.displayManager.autoLogin = {
        enable = true;
        user = "sam";
      };
    };
}
