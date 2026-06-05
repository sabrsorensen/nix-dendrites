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

      authorizedKeyPaths = [
        "atlasuponraiden/emeraldecho"
        "kamino/emeraldecho"
        "zaphodbeeblebrox/emeraldecho"
      ];
    };

    installer = {
      name = "jovian";
    };

    nixRemote = {
      authorizedKeyPaths = [
        "atlasuponraiden/emeraldecho_nix"
        "kamino/emeraldecho_nix"
        "zaphodbeeblebrox/emeraldecho_nix"
      ];
    };
  };
}
