{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-secrets = {
    my.buildSecretRoot = inputs.nix-secrets;
    my.gitSecretRoot = inputs.nix-secrets;
    my.gpgKeysDir = "${inputs.nix-secrets}/gpg-keys";

    sops = {
      defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
      secrets = {
        context7_api_key = { };
        github_nixos_mcp_token = { };
        syncthing_gui_password = { };
      };
    };
  };
}
