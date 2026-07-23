{ inputs, ... }:
{
  flake.modules.nixos.users-emeraldecho =
    { config, lib, ... }:
    lib.mkIf (config.my.host.name == "EmeraldEcho") {
      sops.secrets.hashed_password = {
        owner = "root";
        group = "root";
        mode = "0400";
        neededForUsers = true;
        sopsFile = "${inputs.nix-secrets}/secrets.yaml";
      };
      users.users.sam = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [
          "wheel"
          "networkmanager"
          "audio"
          "video"
        ];
        hashedPasswordFile = config.sops.secrets.hashed_password.path;
        openssh.authorizedKeys.keyFiles = [
          "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/emeraldecho.pub"
          "${inputs.nix-secrets}/ssh-keys/kamino/emeraldecho.pub"
          "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/emeraldecho.pub"
        ];
      };
      users.groups.sam.gid = 1000;
    };
}
