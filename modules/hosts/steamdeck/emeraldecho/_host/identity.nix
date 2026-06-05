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
        "${inputs.nix-secrets}/ssh-keys/atlas/emeraldecho.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino/emeraldecho.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/emeraldecho.pub"
      ];
    };

    installer = {
      name = "jovian";
    };

    nixRemote = {
      authorizedKeys = [
        "${inputs.nix-secrets}/ssh-keys/atlas/emeraldecho_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino/emeraldecho_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/emeraldecho_nix.pub"
      ];
    };
  };
}
