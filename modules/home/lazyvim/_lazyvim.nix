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
      username = if config.my.host.platform == "wsl" then "ssorensen" else "sam";
    in
    lib.mkIf (config.my.host.features.lazyvim && config.my.host.home.enable) {
      home-manager.users.${username} = {
        imports = [ inputs.lazyvim.homeManagerModules.default ];
        programs.lazyvim = {
          enable = true;
          ignoreBuildNotifications = true;
          config = { };
          extras = {
            lang.docker = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
            lang.dotnet = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
            lang.git = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
            lang.json = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
            lang.markdown = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
            lang.nix = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
            lang.python = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
            lang.sql = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
            lang.toml = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
            lang.yaml = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
          };
          extraPackages = [
            pkgs.nixd
            pkgs.alejandra
          ];
          plugins.colorscheme = inputs.lazyvim.lib.lazyConfig [
            {
              plugin = "oxfist/night-owl.nvim";
              lazy = false;
              priority = 1000;
              config = lib.generators.mkLuaInline ''
                function()
                  require("night-owl").setup()
                end
              '';
            }
            {
              plugin = "LazyVim/LazyVim";
              opts.colorscheme = "night-owl";
            }
          ];
          treesitterParsers = [ ];
        };
      };
    };
}
