{ inputs, ... }:
let
  secretRoot = inputs.nix-work-secrets;
  readValue =
    path: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${secretRoot}/${path}");
  keyFiles = builtins.filter (name: builtins.match ".*\\.asc" name != null) (
    builtins.attrNames (builtins.readDir "${secretRoot}/gpg-keys")
  );
in
{
  flake.modules.nixos.wsl-git-gpg =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.platform == "wsl" && config.my.host.home.enable) {
      home-manager.users.ssorensen = {
        programs.git = {
          enable = true;
          settings = {
            user = {
              name = readValue "git/name.txt";
              email = readValue "git/email.txt";
              signingKey = readValue "gpg-keys/signing-key-hash-wsl.txt";
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
        programs.gpg = {
          enable = true;
          mutableKeys = true;
          mutableTrust = true;
          publicKeys = map (name: {
            source = "${secretRoot}/gpg-keys/${name}";
            trust = "ultimate";
          }) keyFiles;
        };
        services.gpg-agent = {
          enable = true;
          defaultCacheTtl = 1800;
          maxCacheTtl = 7200;
          enableFishIntegration = true;
          enableSshSupport = true;
          pinentry.package = pkgs.pinentry-curses;
          extraConfig = ''
            allow-loopback-pinentry
            default-cache-ttl-ssh 1800
            max-cache-ttl-ssh 7200
          '';
        };
        systemd.user.services.gpg-cleanup-stale-locks = {
          Unit = {
            Description = "Remove stale GPG keybox lock files";
            Before = [ "gpg-agent.service" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.findutils}/bin/find %h/.gnupg -name .#lk* -delete 2>/dev/null; rm -f %h/.gnupg/public-keys.d/pubring.db.lock'";
          };
          Install.WantedBy = [ "gpg-agent.service" ];
        };
      };
    };
}
