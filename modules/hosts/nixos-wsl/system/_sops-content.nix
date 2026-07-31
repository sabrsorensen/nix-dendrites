{
  secretsFile,
  username,
  ...
}:
{
  sops = {
    defaultSopsFile = secretsFile;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.github_nixos_wsl_token = {
      owner = username;
      group = "root";
      mode = "0400";
    };
  };
}
