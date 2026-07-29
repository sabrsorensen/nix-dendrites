{ ... }:
{
  flake.modules.nixos.bootstrap-enroll =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      enabled = builtins.elem "bootstrap" config.my.host.tags;
      finalName =
        if config.my.host.bootstrap.finalConfigName != null then
          config.my.host.bootstrap.finalConfigName
        else
          config.my.host.name;
      instructionsEtcPath = lib.removePrefix "/etc/" config.my.host.bootstrap.instructionsPath;
      enroll = pkgs.writeShellApplication {
        name = "bootstrap-enroll";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.ssh-to-age
        ];
        text = ''
          set -eu
          host_name=${lib.escapeShellArg config.networking.hostName}
          ssh_pub=/etc/ssh/ssh_host_ed25519_key.pub
          final_config=${lib.escapeShellArg finalName}

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
          echo "3. Switch to the final host config:"
          echo "   sudo nixos-rebuild switch --flake <flake>#$final_config"
        '';
      };
    in
    lib.mkIf enabled {
      assertions = [
        {
          assertion = lib.hasPrefix "/etc/" config.my.host.bootstrap.instructionsPath;
          message = "my.host.bootstrap.instructionsPath must be rooted under /etc.";
        }
      ];
      environment.systemPackages = [ enroll ];
      environment.etc.${instructionsEtcPath}.text = ''
        Bootstrap enrollment helper for ${config.networking.hostName}

        Run:
          sudo bootstrap-enroll
      '';
    };
}
