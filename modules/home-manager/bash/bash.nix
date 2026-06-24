{
  flake.modules.homeManager.bash =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {

      programs.bash = {
        enable = true;
        enableCompletion = true;
        profileExtra = lib.optionalString config.my.host.is.steamdeck ''
          if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
            . "$HOME/.nix-profile/etc/profile.d/nix.sh"
          fi
        '';
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
