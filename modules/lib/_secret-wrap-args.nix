{ lib }:
specs:
builtins.filter (arg: arg != "") (
  map (
    {
      envName,
      secretPath,
    }:
    lib.optionalString (secretPath != null) "--run 'export ${envName}=\"$(cat ${secretPath})\"'"
  ) specs
)
