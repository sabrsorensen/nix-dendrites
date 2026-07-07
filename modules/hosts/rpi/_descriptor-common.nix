{
  inputs,
  lib,
  aarch64Helpers,
}:
{
  mkResolvedImports =
    {
      defaultNixosImports,
      systemType ? null,
      extraImports ? [ ],
      serviceImports ? [ ],
    }:
    serviceImports
    ++ defaultNixosImports
    ++ extraImports
    ++ lib.optionals (systemType != null) [ inputs.self.modules.nixos.${systemType} ];

  mkImageInventoryOutputs =
    image:
    lib.optionals (image.enable && image.outputName != null && image.configuration != null) (
      builtins.map (output: output // { buildProduct = "sdImage"; }) (
        aarch64Helpers.mkAarch64Outputs {
          name = image.outputName;
          configuration = image.configuration;
        }
      )
    );

  mkBootstrapInventoryOutputs =
    bootstrap:
    lib.optionals (bootstrap != null) (
      aarch64Helpers.mkAarch64Outputs {
        name = bootstrap.outputName;
        configuration = bootstrap.configurationName;
      }
      ++ builtins.map (output: output // { buildProduct = "sdImage"; }) (
        aarch64Helpers.mkAarch64Outputs {
          name = bootstrap.imageOutputName;
          configuration = bootstrap.imageName;
        }
      )
    );
}
