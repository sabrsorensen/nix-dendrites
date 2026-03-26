{
  flake.modules.homeManager.bash =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.nix-index = {
        enable = true;
        enableBashIntegration = true;
      };

      programs.bash = {
        enable = true;
        enableCompletion = true;
        bashrcExtra = ''
          # If not running interactively, don't do anything
          [[ $- != *i* ]] && return

          if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && $SHLVL == 1 || -n $TMUX ]]
          then
                  shopt -q login_shell && LOGIN_OPTION="--login" || LOGIN_OPTION=""
                  exec fish $LOGIN_OPTION
          fi
        '';
      };
    };
}
