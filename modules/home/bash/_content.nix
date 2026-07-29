{
  isSteamDeck,
  nixProfile,
}:
{
  enable = true;
  enableCompletion = true;
  profileExtra = if isSteamDeck then ''
    if [ -e "${nixProfile}" ]; then
      . "${nixProfile}"
    fi
  '' else "";
  bashrcExtra = ''
    # If not running interactively, don't do anything
    [[ $- != *i* ]] && return

    if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && $SHLVL == 1 || -n $TMUX ]]
    then
            shopt -q login_shell && LOGIN_OPTION="--login" || LOGIN_OPTION=""
            exec fish $LOGIN_OPTION
    fi
  '';
}
