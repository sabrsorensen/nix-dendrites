{
  flake.modules.homeManager.atuin =
    {
      config,
      ...
    }:
    let
      localDomain = config.systemConstants.domain;
    in
    {
      programs.atuin = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        daemon = {
          enable = true;
        };
        forceOverwriteSettings = true;
        settings = {
          sync_address = "https://${localDomain}/atuin/";
          sync_frequency = "0";
          search_mode = "daemon-fuzzy";
          search_mode_shell_up_key_binding = "daemon-fuzzy";
          filter_mode_shell_up_key_binding = "session";
          workspaces = true;
          style = "auto";
          command_chaining = true;
          enter_accept = true;
          keymap_mode = "vim-normal";
          sync = {
            records = true;
          };
          theme = {
            name = "marine";
          };
        };
      };
    };
}
