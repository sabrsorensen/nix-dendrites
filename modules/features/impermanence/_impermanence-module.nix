{ inputs, ... }:
{
  flake.modules.nixos.impermanence =
    {
      config,
      lib,
      utils,
      ...
    }:
    let
      cfg = config.my.host.persistence;
      rollback = cfg.rollback;
      hostKey = "/persist/etc/ssh/ssh_host_ed25519_key";
    in
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      options.my.host.features.persistenceSystem = lib.mkEnableOption "system persistent state";

      options.my.host.persistence = {
        varOnOwnSubvolumes = lib.mkEnableOption ''
          /var/log and /var/lib living on their own persistent filesystems.
          Their state then survives a root rollback without impermanence, and
          bind-mounting them from /persist would collide with those mounts'';

        rollback = {
          enable = lib.mkEnableOption "rolling the btrfs root subvolume back to a blank snapshot on every boot";
          device = lib.mkOption {
            type = lib.types.str;
            default = config.fileSystems."/".device;
            defaultText = lib.literalExpression ''config.fileSystems."/".device'';
            description = "Block device holding the btrfs filesystem (the unlocked LUKS mapper, not the partition).";
          };
          rootSubvolume = lib.mkOption {
            type = lib.types.str;
            default = "root";
            description = "Subvolume mounted at /, deleted and recreated on every boot.";
          };
          blankSubvolume = lib.mkOption {
            type = lib.types.str;
            default = "root-blank";
            description = "Read-only snapshot of the empty root taken at install time.";
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf config.my.host.features.persistenceSystem {
          environment.persistence."/persist" = {
            hideMounts = true;
            directories = [
              "/var/spool"
              "/srv"
              "/etc/NetworkManager/system-connections"
            ]
            ++ lib.optionals (!cfg.varOnOwnSubvolumes) [
              "/var/log"
              "/var/lib/nixos"
              "/var/lib/systemd/coredump"
            ];
            files = [ "/etc/machine-id" ];
          };
          home-manager.sharedModules = [
            {
              home.persistence."/persist" = { };
            }
          ];
          programs.fuse.userAllowOther = true;

          # Keep the SSH host key on /persist directly rather than bind-mounting
          # /etc/ssh: sops-nix derives the host's age identity from it during
          # activation, and must not race impermanence's mounts for it.
          services.openssh.hostKeys = [
            {
              path = hostKey;
              type = "ed25519";
            }
          ];
          sops.age.sshKeyPaths = [ hostKey ];

          # sudo remembers who has seen the lecture under /var/db/sudo, which
          # the rollback wipes, so it would otherwise lecture after every boot.
          security.sudo.extraConfig = ''
            Defaults lecture = never
          '';
        })

        (lib.mkIf rollback.enable {
          assertions = [
            {
              assertion = config.boot.initrd.systemd.enable;
              message = "my.host.persistence.rollback runs as an initrd systemd service and requires boot.initrd.systemd.enable.";
            }
          ];

          boot.initrd.systemd.services.rollback-root = {
            description = "Roll back btrfs root subvolume to a blank snapshot";
            wantedBy = [ "initrd.target" ];
            requires = [ "${utils.escapeSystemdPath rollback.device}.device" ];
            after = [ "${utils.escapeSystemdPath rollback.device}.device" ];
            before = [ "sysroot.mount" ];
            unitConfig.DefaultDependencies = "no";
            serviceConfig.Type = "oneshot";
            # btrfs-progs and coreutils are already in the systemd initrd.
            script = ''
              mkdir -p /rollback
              mount -t btrfs -o subvol=/ ${lib.escapeShellArg rollback.device} /rollback
              root=/rollback/${lib.escapeShellArg rollback.rootSubvolume}

              if [ -e "$root" ]; then
                # Nested subvolumes (e.g. systemd's /var/lib/machines) block
                # deleting their parent; remove the deepest ones first.
                btrfs subvolume list -o "$root" | cut -f9 -d' ' | sort -r |
                  while read -r subvolume; do
                    echo "Deleting nested subvolume /$subvolume"
                    btrfs subvolume delete "/rollback/$subvolume"
                  done
                echo "Deleting root subvolume"
                btrfs subvolume delete "$root"
              fi

              echo "Restoring blank root subvolume"
              btrfs subvolume snapshot /rollback/${lib.escapeShellArg rollback.blankSubvolume} "$root"
              umount /rollback
            '';
          };
        })
      ];
    };
}
