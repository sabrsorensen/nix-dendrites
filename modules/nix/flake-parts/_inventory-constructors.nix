{ lib }:
{
  mkInventorySshBase =
    {
      identityFile,
      user,
      identitiesOnly ? true,
      port ? null,
    }:
    {
      inherit identityFile identitiesOnly user;
    }
    // lib.optionalAttrs (port != null) { inherit port; };

  mkInventorySshNix =
    {
      identityFile,
      enable ? true,
      port ? null,
      user ? null,
    }:
    {
      inherit enable identityFile;
    }
    // lib.optionalAttrs (port != null) { inherit port; }
    // lib.optionalAttrs (user != null) { inherit user; };

  mkInventorySsh =
    {
      base,
      nix ? null,
    }:
    {
      inherit base;
    }
    // lib.optionalAttrs (nix != null) { inherit nix; };

  mkInventorySecureDeploy =
    {
      peerName,
      peerIp,
      probeDomains,
    }:
    {
      inherit peerIp peerName probeDomains;
    };

  mkInventoryDeploy =
    {
      remoteMethod ? "switch",
      secure ? null,
    }:
    {
      inherit remoteMethod;
    }
    // lib.optionalAttrs (secure != null) { inherit secure; };

  mkInventoryBuilder =
    {
      hostName,
      systems,
      maxJobs,
      speedFactor,
      supportedFeatures,
      mandatoryFeatures ? [ ],
      protocol ? "ssh-ng",
      publicHostKey ? null,
      sshKey ? null,
      sshUser ? "nix-remote",
      alias ? null,
    }:
    (
      {
        inherit
          hostName
          mandatoryFeatures
          maxJobs
          protocol
          publicHostKey
          sshKey
          sshUser
          speedFactor
          supportedFeatures
          systems
          ;
      }
      // lib.optionalAttrs (alias != null) { inherit alias; }
    );

  mkInventoryHost =
    {
      builder ? null,
      dnsConfigurations ? null,
      deploy ? null,
      outputs ? [ ],
      platform ? null,
      serviceRoles ? [ ],
      ssh ? null,
    }:
    (lib.optionalAttrs (builder != null) { inherit builder; })
    // (lib.optionalAttrs (ssh != null) { inherit ssh; })
    // (lib.optionalAttrs (dnsConfigurations != null) { inherit dnsConfigurations; })
    // (lib.optionalAttrs (deploy != null) { inherit deploy; })
    // (lib.optionalAttrs (platform != null) { inherit platform; })
    // (lib.optionalAttrs (serviceRoles != [ ]) { inherit serviceRoles; })
    // {
      inherit outputs;
    };
}
