{
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.lazyvim =
    {
      config,
      pkgs,
      ...
    }:
    let
      appName = config.programs.lazyvim.appName;
      lazyBootstrapTarget = "${config.xdg.dataHome}/${appName}/lazy/lazy.nvim";
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
          lazy-core = inputs.lazyvim.lib.lazyConfig {
            plugin = "folke/lazy.nvim";
            dir = "${pkgs.vimPlugins.lazy-nvim}";
            dev = true;
            pin = true;
          };
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

      xdg.dataFile."${appName}/lazy/lazy.nvim".source = pkgs.vimPlugins.lazy-nvim;

      home.activation.lazyvimBootstrapFromNix = inputs.home-manager.lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        target=${lib.escapeShellArg lazyBootstrapTarget}
        if [ -d "$target" ] && [ ! -L "$target" ]; then
          backup="$target.pre-nix-bootstrap"
          rm -rf "$backup"
          mv "$target" "$backup"
        fi
      '';
    };
}
