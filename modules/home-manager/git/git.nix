{
  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      settings = {
        alias = {
          s = "status";
          co = "checkout";
          ci = "commit -p -v";
          ai = "add -p -v";
          br = "branch";
          lg = "log --graph --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
          di = "diff --color-words";
          alias = "!git config --list | grep 'alias\\.' | sed 's/alias\\.\\([^=]*\\)=\\(.*\\)/\\1\\\t => \\2/' | sort";
        };
        branch.sort = "-committerdate";
        color = {
          ui = "auto";
          interactive = "auto";
          diff.whitespace = "red reverse";
        };
        column.ui = "auto";
        commit = {
          verbose = true;
          gpgSign = true;
        };
        core = {
          editor = "vim";
          pager = "less -r";
          whitespace = "trailing-space,space-before-tab";
          excludesFile = "$HOME/.gitignore_global";
          fsmonitor = true;
          untrackedCache = true;
        };
        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
          renames = true;
        };
        fetch = {
          prune = true;
          pruneTags = true;
          all = true;
        };
        help.autocorrect = "prompt";
        init.defaultBranch = "main";
        merge.conflictstyle = "zdiff3";
        pull.rebase = true;
        push = {
          default = "simple";
          autoSetupRemote = true;
          followTags = true;
        };
        rebase = {
          autoStash = true;
          autoSquash = true;
          updateRefs = true;
        };
        rerere = {
          enabled = true;
          autoupdate = true;
        };
        tag = {
          gpgSign = true;
          sort = "-version:refname";
        };
        gpg.program = "gpg";
      };
    };
  };
}
