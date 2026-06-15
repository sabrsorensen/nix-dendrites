{
  inputs,
  ...
}:
{
  flake.modules.homeManager.sam-git =
    {
      config,
      osConfig ? { },
      lib,
      ...
    }:
    let
      secretRoot = config.my.gitSecretRoot;
      readGitValue =
        path: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${secretRoot}/${path}");

      wslSigningKeyPath = "${secretRoot}/gpg-keys/signing-key-hash-wsl.txt";
      signingKey =
        if config.my.git.signingKeyVariant == "wsl" && builtins.pathExists wslSigningKeyPath then
          readGitValue "gpg-keys/signing-key-hash-wsl.txt"
        else
          readGitValue "gpg-keys/signing-key-hash.txt";
    in
    {
      options.my.git.signingKeyVariant = lib.mkOption {
        type = lib.types.enum [
          "default"
          "wsl"
        ];
        default = "default";
        description = "Selects which signing key hash file to use for Git signing.";
      };

      config.programs.git.settings.user = {
        name = readGitValue "git/name.txt";
        email = readGitValue "git/email.txt";
        signingKey = signingKey;
      };
    };
}
