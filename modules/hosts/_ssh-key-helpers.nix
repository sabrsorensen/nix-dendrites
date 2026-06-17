{ config }:
{
  mkBuildSecretSshKeyFiles =
    keyPaths: map (keyPath: "${config.my.buildSecretRoot}/ssh-keys/${keyPath}.pub") keyPaths;
}
