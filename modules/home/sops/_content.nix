{
  homeDirectory,
  inputs,
  isManagedPersonal,
  lib,
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    home.sessionVariables.SOPS_AGE_KEY_CMD = "${pkgs.ssh-to-age}/bin/ssh-to-age -private-key < ${homeDirectory}/.ssh/sops_ed25519";

    sops = {
      age.sshKeyPaths = lib.mkForce [ "${homeDirectory}/.ssh/sops_ed25519" ];
    }
    // lib.optionalAttrs isManagedPersonal {
      defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
      secrets = {
        context7_api_key = { };
        github_nixos_mcp_token = { };
      };
    };
  };
}
