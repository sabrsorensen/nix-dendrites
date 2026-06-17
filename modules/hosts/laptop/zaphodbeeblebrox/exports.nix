{
  inputs,
  lib,
  ...
}:
let
  rootLuksUuid = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/luks/zaphod/root.txt");
in
{
  flake.modules.homeManager.zaphodBeeblebroxHome = {
    imports = with inputs.self.modules.homeManager; [
      firefox
      konsole
      mcp
      mcp-personal
      nix-index
      vscode
    ];
  };

  flake.modules.nixos = {
    zaphodBeeblebrox = {
      imports = [
        ./_zaphod/hardware.nix
        (
          { lib, ... }:
          import ./_zaphod/filesystem.nix {
            inherit lib rootLuksUuid;
          }
        )
        ./_zaphod/network.nix
        ./_zaphod/users/sam.nix
      ];
    };
  };
}
