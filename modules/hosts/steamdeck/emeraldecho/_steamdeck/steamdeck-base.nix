bootMode:
{
  steamUser ? "sam",
  ...
}:
{
  imports = [
    (import ./steamdeck-config.nix bootMode)
    ../../../configuration.nix
  ];

  users.users.${steamUser} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
    ];
  };
}
