{
  inputs,
  ...
}:
{
  primaryHostName = "EmeraldEcho";
  homeConfigurationName = "deck@EmeraldEcho";

  users = {
    steam = {
      name = "sam";
      extraGroups = [
        "wheel"
        "networkmanager"
        "audio"
        "video"
      ];

      authorizedKeys = [
        "${inputs.nix-secrets}/ssh-keys/atlas_emeraldecho.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino_emeraldecho.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphod_emeraldecho.pub"
        "${inputs.nix-secrets}/ssh-keys/wsl_emeraldecho.pub"
      ];
    };

    installer = {
      name = "jovian";
    };

    nixRemote = {
      authorizedKeys = [
        "${inputs.nix-secrets}/ssh-keys/atlas_emeraldecho_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino_emeraldecho_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphod_emeraldecho_nix.pub"
      ];
    };
  };
}
