{ inputs, ... }:
{
  flake.modules.nixos.users-kamino =
    { config, lib, ... }:
    lib.mkIf (config.my.host.name == "Kamino") {
      sops.secrets.hashed_password = {
        owner = "root";
        group = "root";
        mode = "0400";
        neededForUsers = true;
        sopsFile = "${inputs.nix-secrets}/secrets.yaml";
      };
      users.users.sam = {
        isNormalUser = true;
        description = "Sam";
        group = "sam";
        extraGroups = [
          "wheel"
          "dialout"
          "docker"
          "networkmanager"
          "podman"
          "users"
        ];
        hashedPasswordFile = config.sops.secrets.hashed_password.path;
        openssh.authorizedKeys.keyFiles = [ "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/kamino.pub" ];
      };
      users.groups.sam = { };
      services.displayManager.autoLogin = {
        enable = true;
        user = "sam";
      };
    };
}
