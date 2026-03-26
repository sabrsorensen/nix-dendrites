{
  inputs,
  lib,
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
      homeManager."${username}" =
        { pkgs, ... }:
        {
          imports =
            (with inputs.self.modules.homeManager; [
              sam-git
              sam-secrets
              system-desktop
            ])
            ++ [
              "${inputs.nix-secrets}/modules/sam-syncthing-private.nix"
            ];
          home.packages = with pkgs; [
            mediainfo
          ];
        };
    }
  ];
}
