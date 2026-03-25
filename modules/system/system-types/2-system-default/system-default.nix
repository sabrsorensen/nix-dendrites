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
        secrets
        locale
      ]
      ++ (with inputs.self.modules.generic; [
        systemConstants
        pkgs-by-name
      ]);
  };

  flake.modules.homeManager.system-default = {
    imports =
      with inputs.self.modules.homeManager;
      [
        system-minimal
        secrets
      ]
      ++ [ inputs.self.modules.generic.systemConstants ];
  };
}
