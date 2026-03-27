{
  inputs,
  lib,
  self,
  ...
}:

let
  username = "sam";
  userImports = with inputs.self.modules.homeManager; [
    sam-git
    sam-secrets
  ];
  homeImports = [ inputs.self.modules.homeManager.home ];
  graphicalImports = [ inputs.self.modules.homeManager."graphical-home" ];
  privateImports = [
    "${inputs.nix-secrets}/modules/sam-syncthing-private.nix"
    "${inputs.nix-secrets}/modules/sam-secrets-private.nix"
  ];
in
{
  flake.modules = lib.mkMerge [
    (self.factory.user username true)
    {
      nixos."${username}" = {
        imports =
          (with inputs.self.modules.nixos; [
            virtualisation
          ])
          ++ [
            "${inputs.nix-secrets}/modules/system-secrets-private.nix"
          ];

        users.users."${username}" = {
          group = username;
        };
        programs.fish.enable = true;
      };
    }

    {
      nixos.samCli =
        { pkgs, ... }:
        {
          imports = [
            "${inputs.nix-secrets}/modules/system-secrets-private.nix"
          ];

          users.groups."${username}" = { };
          users.users."${username}" = {
            isNormalUser = true;
            home = "/home/${username}";
            extraGroups = [ "wheel" ];
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
          imports = userImports ++ graphicalImports ++ privateImports;
          home.username = lib.mkDefault "sam";
          home.homeDirectory = lib.mkDefault "/home/sam";
        };
    }

    {
      homeManager.samCli =
        { ... }:
        {
          imports = userImports ++ homeImports ++ privateImports;
          home.username = lib.mkDefault "sam";
          home.homeDirectory = lib.mkDefault "/home/sam";
        };
    }
  ];
}
