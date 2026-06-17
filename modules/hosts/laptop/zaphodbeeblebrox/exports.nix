{
  inputs,
  lib,
  ...
}:
let
  rootLuksUuid = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/luks/zaphod/root.txt");
in
{
  flake.modules = {
    homeManager.zaphodBeeblebroxHome = {
      imports = with inputs.self.modules.homeManager; [
        firefox
        konsole
        mcp
        mcp-personal
        nix-index
        vscode
      ];
    };

    nixos = {
      zaphodBeeblebroxHardware = ./_zaphod/hardware.nix;
      zaphodBeeblebroxFilesystem =
        { lib, ... }:
        import ./_zaphod/filesystem.nix {
          inherit lib rootLuksUuid;
        };
      zaphodBeeblebroxNetwork = ./_zaphod/network.nix;
      zaphodBeeblebroxUserSam = ./_zaphod/users/sam.nix;
    };
  };
}
