{ inputs, ... }:
{
  flake.modules.nixos.lazyvim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = if config.my.host.roles.wsl then "ssorensen" else "sam";
    in
    lib.mkIf config.my.host.features.lazyvim {
      home-manager.users.${username} = {
        imports = [ inputs.lazyvim.homeManagerModules.default ];
        programs.lazyvim = {
          enable = true;
          ignoreBuildNotifications = true;
          extras = {
            lang.docker.enable = true;
            lang.dotnet.enable = true;
            lang.git.enable = true;
            lang.json.enable = true;
            lang.markdown.enable = true;
            lang.nix.enable = true;
            lang.python.enable = true;
            lang.sql.enable = true;
            lang.toml.enable = true;
            lang.yaml.enable = true;
          };
          extraPackages = [
            pkgs.nixd
            pkgs.nixfmt
          ];
        };
      };
    };
}
