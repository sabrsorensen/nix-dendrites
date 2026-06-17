{
  inputs,
  lib,
}:
{
  mkNixos = system: name: {
    ${name} = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        inputs.self.modules.nixos.${name}
        { nixpkgs.hostPlatform = lib.mkDefault system; }
      ];
    };
  };

  mkHomeManager =
    systemOrArgs:
    if builtins.isAttrs systemOrArgs then
      let
        args = systemOrArgs;
        name = args.name;
        system = args.system;
        hostName = args.hostName or name;
        hostContext = args.hostContext or null;
        extraSpecialArgs = args.extraSpecialArgs or { };
        extraConfig =
          args.extraConfig or (
            {
              ...
            }:
            { }
          );
        baseModules = args.modules or [ inputs.self.modules.homeManager.${name} ];
        hostDefaults =
          if hostContext == null then
            [ ]
          else
            [
              (
                {
                  ...
                }:
                {
                  my.host = hostContext // {
                    name = hostName;
                    domain = inputs.self.lib.shared.site.domain or null;
                  };
                  home.username = args.username;
                  home.homeDirectory = args.homeDirectory;
                  home.stateVersion = args.stateVersion;
                }
              )
            ];
      in
      {
        ${name} = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.self.overlays.default ];
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inventory = inputs.self.lib.shared.mkHomeManagerInventory inputs.self.lib.hostInventory;
          }
          // extraSpecialArgs;
          modules =
            lib.optionals (inputs ? determinate) [
              inputs.determinate.homeManagerModules.default
            ]
            ++ baseModules
            ++ [
              { nixpkgs.config.allowUnfree = true; }
            ]
            ++ hostDefaults
            ++ [ extraConfig ];
        };
      }
    else
      name:
      inputs.self.lib.mkHomeManager {
        inherit name;
        system = systemOrArgs;
      };
}
