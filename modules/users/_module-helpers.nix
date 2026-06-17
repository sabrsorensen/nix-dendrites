{
  inputs,
  lib,
  ...
}:
let
  nixosModules = inputs.self.modules.nixos;
  homeManagerModules = inputs.self.modules.homeManager;
  mkUserHomePath = username: "/home/${username}";
in
rec {
  mkUserSystemModule =
    {
      username,
      homeModule ? builtins.getAttr username homeManagerModules,
      extraImports ? [ ],
      extraUserConfig ? { },
      extraConfig ? { },
    }:
    {
      pkgs,
      ...
    }:
    {
      imports = [
        (builtins.getAttr "${username}-system-base" nixosModules)
        (builtins.getAttr "${username}-system-private" nixosModules)
      ]
      ++ extraImports;

      users.groups."${username}" = { };
      users.users."${username}" = {
        isNormalUser = true;
        home = mkUserHomePath username;
        group = username;
        shell = pkgs.bash;
      }
      // extraUserConfig;

      home-manager.users."${username}" = {
        imports = [ homeModule ];
      };
    }
    // extraConfig;

  mkUserHomeModule =
    imports:
    { ... }:
    {
      inherit imports;
    };

  mkUserVariantModules =
    {
      username,
      systemModuleName ? username,
      homeModuleName ? username,
      homeImports,
      extraSystemImports ? [ ],
      extraUserConfig ? { },
      extraSystemConfig ? { },
    }:
    {
      nixos."${systemModuleName}" = mkUserSystemModule {
        inherit
          username
          extraUserConfig
          ;
        homeModule = homeManagerModules."${homeModuleName}";
        extraImports = extraSystemImports;
        extraConfig = extraSystemConfig;
      };

      homeManager."${homeModuleName}" = mkUserHomeModule homeImports;
    };

  mkUserFamily =
    {
      username,
      homeConfigurationSystem ? null,
      variants,
    }:
    let
      homeConfigurations = lib.optionalAttrs (homeConfigurationSystem != null) {
        "${username}" = inputs.self.lib.mkHomeManager homeConfigurationSystem username;
      };
    in
    {
      flake = {
        inherit homeConfigurations;
        modules = lib.mkMerge (
          map (variant: mkUserVariantModules ({ inherit username; } // variant)) variants
        );
      };
    };
}
