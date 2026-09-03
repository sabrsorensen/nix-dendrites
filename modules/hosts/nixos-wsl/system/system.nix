{ inputs, ... }:
{
  flake-file.inputs.nix-work-secrets = {
    url = "git+https://github.com/sabrsorensen/nix-work-secrets.git";
    flake = false;
  };

  flake.modules.nixos.system-nixos-wsl =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = "ssorensen";
      certDir = "${inputs.nix-work-secrets}/certs";
      secretsFile = "${inputs.nix-work-secrets}/secrets/wsl.yaml";
    in
    lib.mkIf (config.my.host.name == "NixOS-WSL") (
      import ./_system.nix (
        args
        // {
          inherit
            certDir
            secretsFile
            username
            ;
        }
      )
    );
}
