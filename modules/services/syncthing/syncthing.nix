{
  flake.modules.nixos.syncthing = {
    services.syncthing = {
      openDefaultPorts = true;
    };
  };
}
