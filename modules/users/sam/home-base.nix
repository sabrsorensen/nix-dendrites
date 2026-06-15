{
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.sam-home-base = {
    imports = with inputs.self.modules.homeManager; [
      sam-git
      sam-secrets
    ];

    home.username = lib.mkDefault "sam";
    home.homeDirectory = lib.mkDefault "/home/sam";
  };
}
