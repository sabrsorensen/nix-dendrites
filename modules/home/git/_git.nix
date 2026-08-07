{
  inputs,
  lib,
  ...
}:
let
  gitValue =
    path: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${inputs.nix-secrets}/${path}");
in
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = gitValue "git/name.txt";
        email = gitValue "git/email.txt";
        signingKey = gitValue (
          if builtins.pathExists "${inputs.nix-secrets}/gpg-keys/signing-key-hash-wsl.txt" then
            "gpg-keys/signing-key-hash-wsl.txt"
          else
            "gpg-keys/signing-key-hash.txt"
        );
      };
      alias = {
        s = "status";
        co = "checkout";
        ci = "commit -p -v";
        ai = "add -p -v";
        br = "branch";
        sync-develop = "!git switch develop && git fetch upstream && git merge --ff-only upstream/develop && git push origin develop";
        sync-release = "!git switch release && git fetch upstream && git merge --ff-only upstream/release && git push origin release";
        sync-main = "!git switch main && git fetch upstream && git merge --ff-only upstream/main && git push origin main";
        sync-master = "!git switch master && git fetch upstream && git merge --ff-only upstream/master && git push origin master";
        lg = "log --graph --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        di = "diff --color-words";
        alias = "!git config --list | grep 'alias\\.' | sed 's/alias\\.\\([^=]*\\)=\\(.*\\)/\\1\\\t => \\2/' | sort";
      };
      branch.sort = "-committerdate";
      column.ui = "auto";
      color = {
        ui = "auto";
        interactive = "auto";
        diff.whitespace = "red reverse";
      };
      commit = {
        verbose = true;
        gpgSign = true;
      };
      core = {
        editor = "vim";
        pager = "less -r";
        excludesFile = "$HOME/.gitignore_global";
        fsmonitor = true;
        untrackedCache = true;
        whitespace = "trailing-space,space-before-tab";
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
}
