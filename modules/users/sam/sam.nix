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
  flake.homeConfigurations = inputs.self.lib.mkHomeManager "x86_64-linux" "sam";

  flake.modules = lib.mkMerge [
    (self.lib.factory.user username true)
    {
      nixos."${username}" =
        { ... }:
        {
          imports = with inputs.self.modules.nixos; [
            sam-system-base
            sam-system-private
            virtualisation
          ];
        };
    }

    {
      nixos.samCli =
        {
          pkgs,
          ...
        }:
        {
          imports = with inputs.self.modules.nixos; [
            sam-system-base
            sam-system-private
          ];

          users.groups."${username}" = { };
          users.users."${username}" = {
            isNormalUser = true;
            home = "/home/${username}";
            extraGroups = [
              "media"
              "podman"
              "wheel"
            ];
            shell = pkgs.bash;
            group = username;
          };

          home-manager.users."${username}" = {
            imports = [
              inputs.self.modules.homeManager.samCli
            ];
          };

          programs.fish.enable = true;
        };
    }

    {
      homeManager."${username}" =
        { ... }:
        {
          imports = with inputs.self.modules.homeManager; [
            sam-home-base
            sam-home-graphical
            sam-home-private
          ];
        };
    }

    {
      homeManager.samCli =
        { ... }:
        {
          imports = with inputs.self.modules.homeManager; [
            home
            sam-home-base
            sam-home-private
          ];
        };
    }
  ];
}
