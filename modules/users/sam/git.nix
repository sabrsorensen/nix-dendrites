{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-git =
    { osConfig, ... }:
    let
      hostName = osConfig.networking.hostName;
      readGitValue =
        path:
        builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${inputs.nix-secrets}/${path}");

      wslSigningKeyPath = "${inputs.nix-secrets}/gpg-keys/signing-key-hash-wsl.txt";
      signingKey =
        if hostName == "NixOS-WSL" && builtins.pathExists wslSigningKeyPath then
          readGitValue "gpg-keys/signing-key-hash-wsl.txt"
        else
          readGitValue "gpg-keys/signing-key-hash.txt";
    in
    {
      programs.git.settings.user = {
        name = readGitValue "git/name.txt";
        email = readGitValue "git/email.txt";
        signingKey = signingKey;
      };
    };
}
