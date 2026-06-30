{
  flake.modules.nixos."bootstrap-enroll" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hostName = config.networking.hostName;
      instructionsEtcPath = lib.removePrefix "/etc/" config.my.host.bootstrap.instructionsPath;
      finalConfigName =
        if config.my.host.bootstrap.finalConfigName != null then
          config.my.host.bootstrap.finalConfigName
        else
          config.my.host.name;
      enrollScript = pkgs.writeShellApplication {
        name = "bootstrap-enroll";
        runtimeInputs = with pkgs; [
          coreutils
          ssh-to-age
        ];
        text = ''
          set -eu

          host_name=${lib.escapeShellArg hostName}
          ssh_pub=/etc/ssh/ssh_host_ed25519_key.pub
          final_config=${lib.escapeShellArg (if finalConfigName != null then finalConfigName else "")}

          echo "Bootstrap enrollment for $host_name"
          echo

          if [ ! -r "$ssh_pub" ]; then
            echo "Missing SSH host public key: $ssh_pub" >&2
            exit 1
          fi

          echo "SSH host public key:"
          cat "$ssh_pub"
          echo

          echo "age recipient derived from the SSH host key:"
          ssh-to-age < "$ssh_pub"
          echo

          echo "Next steps:"
          echo "1. Add the derived age recipient to your secrets policy."
          echo "2. Re-encrypt the host secrets."

          if [ -n "$final_config" ]; then
            echo "3. Switch to the final host config:"
            echo "   sudo nixos-rebuild switch --flake <flake>#$final_config"
          else
            echo "3. Switch to the final host config once secrets are available."
          fi
        '';
      };
    in
    {
      options.my.host.bootstrap = {
        enable = lib.mkEnableOption "bootstrap enrollment helper tooling";

        finalConfigName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Final NixOS configuration name to deploy after bootstrap enrollment.";
        };

        instructionsPath = lib.mkOption {
          type = lib.types.str;
          default = "/etc/bootstrap-enroll.txt";
          description = "Path where bootstrap enrollment instructions are published.";
        };
      };

      config = lib.mkIf config.my.host.bootstrap.enable {
        assertions = [
          {
            assertion = lib.hasPrefix "/etc/" config.my.host.bootstrap.instructionsPath;
            message = "my.host.bootstrap.instructionsPath must be rooted under /etc.";
          }
        ];

        environment.systemPackages = [ enrollScript ];

        environment.etc.${instructionsEtcPath}.text = ''
          Bootstrap enrollment helper for ${hostName}

          Run:
            sudo bootstrap-enroll
        '';
      };
    };
}
