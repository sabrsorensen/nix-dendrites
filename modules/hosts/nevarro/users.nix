{ inputs, ... }:
{
  flake.modules.nixos.users-nevarro =
    { config, lib, ... }:
    lib.mkIf (config.my.host.name == "Nevarro") {
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
          "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/nevarro.pub"
          "${inputs.nix-secrets}/ssh-keys/kamino/nevarro.pub"
          "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/nevarro.pub"
        ];
      };
      users.groups.sam = { };
    };
}
