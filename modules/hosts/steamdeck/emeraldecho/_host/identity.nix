{
  inputs,
  ...
}:
{
  primaryHostName = "EmeraldEcho";
  homeConfigurationName = "deck@EmeraldEcho";
  steamUser = "sam";
  installerUser = "jovian";

  steamUserExtraGroups = [
    "wheel"
    "networkmanager"
    "audio"
    "video"
  ];

  steamUserAuthorizedKeys = [
    "${inputs.nix-secrets}/ssh-keys/atlas_emeraldecho.pub"
    "${inputs.nix-secrets}/ssh-keys/kamino_emeraldecho.pub"
    "${inputs.nix-secrets}/ssh-keys/zaphod_emeraldecho.pub"
    "${inputs.nix-secrets}/ssh-keys/wsl_emeraldecho.pub"
  ];

  nixRemoteAuthorizedKeys = [
    "${inputs.nix-secrets}/ssh-keys/atlas_emeraldecho_nix.pub"
    "${inputs.nix-secrets}/ssh-keys/zaphod_emeraldecho_nix.pub"
  ];
}
