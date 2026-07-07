{
  inputs,
  lib,
  ...
}:
let
  hostModules = inputs.self.modules;
  inherit (inputs.self.lib)
    mkInventoryDeploy
    mkInventoryHost
    mkInventorySsh
    mkInventorySshBase
    mkInventorySshNix
    mkNixosOutputs
    ;
in
rec {
  mkX86Inventory =
    {
      name,
      outputName ? lib.strings.toLower name,
      outputs ? null,
      userName ? null,
      identityFile ? null,
      nixIdentityFile ? null,
      deployRemoteMethod ? null,
      builder ? null,
      extraInventory ? { },
    }:
    mkInventoryHost (
      {
        outputs =
          if outputs != null then
            outputs
          else
            mkNixosOutputs {
              system = "x86_64-linux";
              name = outputName;
              configuration = name;
            };
      }
      // lib.optionalAttrs (userName != null && identityFile != null && nixIdentityFile != null) {
        ssh = mkInventorySsh {
          base = mkInventorySshBase {
            user = userName;
            inherit identityFile;
          };
          nix = mkInventorySshNix {
            identityFile = nixIdentityFile;
          };
        };
      }
      // lib.optionalAttrs (deployRemoteMethod != null) {
        deploy = mkInventoryDeploy {
          remoteMethod = deployRemoteMethod;
        };
      }
      // lib.optionalAttrs (builder != null) {
        inherit builder;
      }
      // extraInventory
    );

  mkX86Descriptor =
    {
      name,
      hostName ? name,
      homeImports ? [ ],
      nixosImports,
      systemType ? null,
      config ? { },
      inventory,
      user ? null,
      localDnsRecords ? [ ],
      bootstrap ? null,
    }:
    {
      inherit
        name
        hostName
        config
        inventory
        bootstrap
        ;
      home.imports = homeImports;
      nixos.imports = nixosImports ++ lib.optionals (systemType != null) [ hostModules.nixos.${systemType} ];
    }
    // lib.optionalAttrs (user != null) {
      inherit user;
    }
    // lib.optionalAttrs (localDnsRecords != [ ]) {
      inherit localDnsRecords;
    };

  mkProfiledX86Descriptor =
    {
      name,
      hostName ? name,
      outputName ? lib.strings.toLower name,
      hostModule,
      config ? { },
      userName ? null,
      identityFile ? null,
      nixIdentityFile ? null,
      authorizedKeys ? { },
      homeImports ? [ ],
      defaultHomeImports ? [ ],
      nixosImports ? [ ],
      extraImports ? [ ],
      systemType ? null,
      defaultSystemType ? null,
      defaultNixosImports ? [ ],
      enableSystemdBoot ? false,
      enableDisko ? false,
      localDnsRecords ? [ ],
      builder ? null,
      extraInventory ? { },
      deployRemoteMethod ? null,
      bootstrap ? null,
    }:
    let
      resolvedSystemType = if systemType != null then systemType else defaultSystemType;
      resolvedHomeImports = defaultHomeImports ++ homeImports;
      resolvedNixosImports =
        defaultNixosImports
        ++ nixosImports
        ++ [ hostModule ]
        ++ extraImports
        ++ lib.optionals enableSystemdBoot [ hostModules.nixos."systemd-boot" ]
        ++ lib.optionals enableDisko [ hostModules.nixos.disko ];
      user =
        if userName != null && identityFile != null && nixIdentityFile != null then
          {
            name = userName;
            ssh = {
              inherit identityFile nixIdentityFile;
            };
          }
          // lib.optionalAttrs (authorizedKeys != { }) {
            inherit authorizedKeys;
          }
        else
          null;
    in
    mkX86Descriptor {
      inherit
        name
        hostName
        config
        user
        localDnsRecords
        bootstrap
        ;
      homeImports = resolvedHomeImports;
      nixosImports = resolvedNixosImports;
      systemType = resolvedSystemType;
      inventory = mkX86Inventory {
        inherit
          name
          outputName
          userName
          identityFile
          nixIdentityFile
          deployRemoteMethod
          builder
          extraInventory
          ;
        outputs =
          mkNixosOutputs {
            system = "x86_64-linux";
            name = outputName;
            configuration = name;
          }
          ++ lib.optionals (bootstrap != null) (mkNixosOutputs {
            system = "x86_64-linux";
            name = bootstrap.outputName;
            configuration = bootstrap.configurationName;
          });
      };
    };
}
