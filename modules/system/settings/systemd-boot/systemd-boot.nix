{
  flake.modules.nixos.systemd-boot =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.boot.loader.systemd-boot;
      mirroredTargets = lib.concatStringsSep " " (map lib.escapeShellArg cfg.mirroredEspPaths);
    in
    {
      options.boot.loader.systemd-boot.mirroredEspPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "/boot2" ];
        description = ''
          Additional mounted EFI System Partition paths to mirror from the
          primary `efiSysMountPoint` after `systemd-boot` installs or updates
          boot entries during a rebuild.
        '';
      };

      config.boot.loader = {
        systemd-boot = {
          enable = true;
          consoleMode = "max";
          extraInstallCommands = lib.mkAfter (
            lib.optionalString (cfg.mirroredEspPaths != [ ]) ''
              for target in ${mirroredTargets}; do
                if [ -d "$target" ]; then
                  echo "Mirroring ${config.boot.loader.efi.efiSysMountPoint} to $target"
                  ${pkgs.rsync}/bin/rsync -a --delete \
                    ${lib.escapeShellArg "${config.boot.loader.efi.efiSysMountPoint}/"} \
                    "$target/"
                else
                  echo "Skipping missing mirrored ESP $target" >&2
                fi
              done
            ''
          );
        };
      };
    };
}
