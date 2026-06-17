{
  inputs,
  ...
}:
{
  flake.modules.nixos."deploy-builder-defaults" =
    { config, lib, ... }:
    let
      enableBuilderDefaults = !(config.my.host.roles.wsl or false);
      currentBuilderHostNames = builtins.filter (name: name != null) [
        (config.my.host.name or null)
        (config.networking.hostName or null)
      ];
      builders = builtins.filter (
        builder:
        builder != null && !(builtins.elem (builder.hostName or null) currentBuilderHostNames)
      ) (
        map (host: host.builder or null) (builtins.attrValues inputs.self.lib.hostInventory)
      );
      buildMachines = map (builder: builtins.removeAttrs builder [ "alias" ]) builders;
      mkBuilderSubstituter =
        builder:
        let
          protocol = builder.protocol or "ssh-ng";
          authority = "${
            lib.optionalString (builder.sshUser != null) "${builder.sshUser}@"
          }${builder.hostName}";
          query = builtins.filter (part: part != null) [
            (if builder.sshKey != null then "ssh-key=${builder.sshKey}" else null)
            (
              if builder.publicHostKey != null then
                "base64-ssh-public-host-key=${builder.publicHostKey}"
              else
                null
            )
          ];
        in
        "${protocol}://${authority}${
          lib.optionalString (query != [ ]) "?${lib.concatStringsSep "&" query}"
        }";
      builderSubstituters = map mkBuilderSubstituter builders;
    in
    lib.mkIf enableBuilderDefaults {
      my.host.nix.buildMachines = lib.mkDefault buildMachines;

      nix.settings.extra-substituters = lib.mkAfter builderSubstituters;
    };
}
