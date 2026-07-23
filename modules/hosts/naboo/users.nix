{ inputs, ... }:
{
  flake.modules.nixos.users-naboo =
    { config, lib, ... }:
    lib.mkIf (config.my.host.name == "Naboo") {
      sops.secrets.hashed_password = {
        owner = "root";
        group = "root";
        mode = "0400";
        neededForUsers = true;
        sopsFile = "${inputs.nix-secrets}/secrets.yaml";
      };
      users.users.sam = {
        isNormalUser = true;
        group = "sam";
        extraGroups = [
          "wheel"
          "video"
        ];
        hashedPasswordFile = config.sops.secrets.hashed_password.path;
        openssh.authorizedKeys.keyFiles = [
          "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/naboo.pub"
          "${inputs.nix-secrets}/ssh-keys/kamino/naboo.pub"
          "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/naboo.pub"
        ];
      };
      users.groups.sam = { };
    };
}
