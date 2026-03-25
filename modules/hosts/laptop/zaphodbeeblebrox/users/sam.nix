{
  inputs,
  self,
  ...
}:
{
  flake.modules.nixos.ZaphodBeeblebrox =
    { config, ... }:
    {
      imports =
        with inputs.self.modules.nixos;
        with inputs.self.factory;
        [
          sam
        ];

      users.users.sam.extraGroups = [
        "dialout"
        "docker"
        "networkmanager"
        "users"
      ];

      home-manager.users.sam = {
      };
      services = {
        displayManager = {
          autoLogin = {
            enable = true;
            user = "sam";
          };
        };
      };
    };
}
