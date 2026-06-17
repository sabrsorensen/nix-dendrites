{
  inputs,
  lib,
  ...
}:
let
  mkWorkstation = import ./_base/workstation.nix;
  mkRegisteredHost =
    descriptor:
    let
      homeModule = descriptor.home.module;
      primaryUser = descriptor.user.name;
      config =
        {
          my.host.primaryInteractiveUser = primaryUser;
          home-manager.users.${primaryUser}.imports = [
            inputs.self.modules.homeManager.${descriptor.name}
          ];
        }
        // (descriptor.config or { });
    in
    mkWorkstation {
      inherit
        inputs
        lib
        homeModule
        primaryUser
        config
        ;
      name = descriptor.name;
      nixosImports = descriptor.nixos.imports or [ ];
      sshIdentityFile = descriptor.user.ssh.identityFile;
      nixIdentityFile = descriptor.user.ssh.nixIdentityFile;
    };
in
{
  inherit mkRegisteredHost;
}
