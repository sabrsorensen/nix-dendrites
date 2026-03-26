{
  inputs,
  ...
}:
{
  # import all essential nix-tools which are used in all modules of a specific class

  flake.modules.nixos.system-default = {
    imports =
      with inputs.self.modules.nixos;
      [
        system-minimal
        home-manager
        nix-ld
        secrets-base
        locale
      ]
      ++ (with inputs.self.modules.generic; [
        systemConstants
        pkgs-by-name
      ])
      ++ [ "${inputs.nix-secrets}/modules/system-secrets-private.nix" ];
  };

  flake.modules.homeManager.system-default = {
    imports =
      with inputs.self.modules.homeManager;
      [
        system-minimal
        secrets-base
        secrets-context
      ]
      ++ [ inputs.self.modules.generic.systemConstants ];
  };
}
