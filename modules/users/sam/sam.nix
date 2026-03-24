{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:

let
  username = "sam";
in
{
  flake.modules = lib.mkMerge [
    (self.factory.user username true)
    {
      nixos."${username}" = {
        imports = with inputs.self.modules.nixos; [
        ];

        users.users."${username}" = {
          initialPassword = "changeme";
          group = username;
        };
        programs.fish.enable = true;
      };
    }

    {
      homeManager."${username}" = {
        imports = with inputs.self.modules.homeManager; [
          system-desktop
        ];
        home.packages = with pkgs; [
          mediainfo
        ];
      };
    }
  ];
}