{ inputs, ... }:
let
  homeModule =
    {
      lib,
      pkgs,
      ...
    }:
    {
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
  featureModule =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.features.lazyvim = lib.mkEnableOption "LazyVim";
      imports = [ inputs.lazyvim.homeManagerModules.default ];
      config = lib.mkIf config.my.features.lazyvim (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.lazyvim = featureModule;
}
