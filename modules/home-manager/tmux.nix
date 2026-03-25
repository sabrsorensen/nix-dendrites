{
  flake.modules.homeManager.tmux = {
    programs.tmux = {
      enable = true;
      clock24 = true;
      extraConfig = ''
        setw -g mode-keys vi
        set -g default-terminal "xterm-256color"
        setw -g monitor-activity on
        set -g visual-activity on
        set mouse on

        # Smart pane switching with awareness of vim splits
        is_vim='echo "#{pane_current_command}" | grep -iqE "(^|\/)g?(view|n?vim?)(diff)?$"'
        bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
        bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
        bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
        bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"
        bind -n C-\\ if-shell "$is_vim" "send-keys C-\\" "select-pane -l"

        bind-key r refresh-client \; display-message "Refreshed!"

        # y and p as in vim
        bind Escape copy-mode
        unbind p
        bind p paste-buffer
        bind -T copy-mode-vi 'v' send-keys -X begin-selection
        bind -T copy-mode-vi 'y' send-keys -X copy-selection
        bind -T copy-mode-vi 'Space' send-keys -X halfpage-down
        bind -T copy-mode-vi 'Bspace' send-keys -X halfpage-up

        # extra commands for interacting with the ICCCM clipboard
        bind C-c run "tmux save-buffer - | xclip -i -sel clipboard"
        bind C-v run "tmux set-buffer \"$(xclip -o -sel clipboard)\"; tmux paste-buffer"

        # easy-to-remember split pane commands
        bind | split-window -h
        bind - split-window -v
        unbind '"'
        unbind %

        # resize panes with vim movement keys
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5
      '';
    };
  };
}
