{
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.lazyvim =
    {
      pkgs,
      ...
    }:
    let
    in
    {
      imports = [ inputs.lazyvim.homeManagerModules.default ];
      programs.lazyvim = {
        enable = true;
        ignoreBuildNotifications = true;
        config = { };
        extras = {
          lang.docker = {
            enable = true;
            installDependencies = true; # Install ruff
            installRuntimeDependencies = true; # Install python3
          };
          lang.dotnet = {
            enable = true;
            installDependencies = true; # Install ruff
            installRuntimeDependencies = true; # Install python3
          };
          lang.git = {
            enable = true;
            installDependencies = true; # Install ruff
            installRuntimeDependencies = true; # Install python3
          };
          lang.json = {
            enable = true;
            installDependencies = true; # Install ruff
            installRuntimeDependencies = true; # Install python3
          };
          lang.markdown = {
            enable = true;
            installDependencies = true; # Install ruff
            installRuntimeDependencies = true; # Install python3
          };
          lang.nix = {
            enable = true;
            installDependencies = true; # Install ruff
            installRuntimeDependencies = true; # Install python3
          };
          lang.python = {
            enable = true;
            installDependencies = true; # Install ruff
            installRuntimeDependencies = true; # Install python3
          };
          lang.sql = {
            enable = true;
            installDependencies = true; # Install ruff
            installRuntimeDependencies = true; # Install python3
          };
          lang.toml = {
            enable = true;
            installDependencies = true; # Install ruff
            installRuntimeDependencies = true; # Install python3
          };
          lang.yaml = {
            enable = true;
            installDependencies = true; # Install ruff
            installRuntimeDependencies = true; # Install python3
          };
        };

        extraPackages = with pkgs; [
          nixd # Nix LSP
          alejandra # Nix formatter
        ];
        plugins = {
          colorscheme = inputs.lazyvim.lib.lazyConfig [
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
          markdown-preview = inputs.lazyvim.lib.lazyConfig {
            plugin = "iamcco/markdown-preview.nvim";
            build = false;
          };
        };

        # Only needed for languages not covered by LazyVim extras
        treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
        ];
      };
    };
}
