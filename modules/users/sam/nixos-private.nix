{
  inputs,
  ...
}:
{
  flake.modules.nixos.sam-system-private = {
    sops = {
      defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
      secrets = {
        hashed_password = {
          owner = "root";
          group = "root";
          mode = "0400";
          neededForUsers = true;
        };
        github_nixos_token = {
          owner = "sam";
          group = "sam";
          mode = "0400";
        };
        ghcr_token = {
          owner = "root";
          group = "root";
          mode = "0400";
        };
        syncthing_gui_password = {
          owner = "sam";
          group = "sam";
          mode = "0400";
        };
      };
    };
  };
}
