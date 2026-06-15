{ lib, ... }:
let
  scriptDir = ./demlo/scripts;
  scriptEntries = builtins.readDir scriptDir;
  scriptFiles = builtins.attrNames (lib.filterAttrs (_name: type: type == "regular") scriptEntries);
in
{
  flake.modules.homeManager.demlo = {
    xdg.configFile = {
      "demlo/config.lua".source = ./demlo/config.lua;
    }
    // builtins.listToAttrs (
      map (name: {
        name = "demlo/scripts/${name}";
        value.source = scriptDir + "/${name}";
      }) scriptFiles
    );
  };
}
