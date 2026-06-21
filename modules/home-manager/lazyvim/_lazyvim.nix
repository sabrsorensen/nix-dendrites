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
        config = {
          options = ''
            require("lazy").setup({
              "oxfist/night-owl.nvim",
              lazy = false, -- make sure we load this during startup if it is your main colorscheme
              priority = 1000, -- make sure to load this before all the other start plugins
              config = function()
                -- load the colorscheme here
                require("night-owl").setup()
                vim.cmd.colorscheme("night-owl")
              end,
            })
          '';
        };
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
        };

        # Only needed for languages not covered by LazyVim extras
        treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
        ];
      };
    };
}
