{ ... }:
{
  flake.modules.nixos.clamav =
    { config, lib, ... }:
    let
      host = config.my.host;
    in
    {
      # On by default for the laptops, the Steam Deck and the x86 server. Off on
      # the Raspberry Pis (clamd pins ~1 GB of RAM for its signature DB), on
      # WSL, and on short-lived installer/bootstrap images. A host overrides
      # with `my.host.features.clamav = true|false;`.
      options.my.host.features.clamav =
        lib.mkEnableOption "ClamAV daemon, signature updates and daily scan"
        // {
          default =
            !(
              host.is.rpi
              || host.platform == "wsl"
              || lib.elem "bootstrap" host.tags
              || lib.elem "installer" host.tags
            );
          defaultText = lib.literalExpression ''
            !(is.rpi || platform == "wsl" || elem "bootstrap" tags || elem "installer" tags)
          '';
        };
      config = lib.mkIf config.my.host.features.clamav (import ./_clamav.nix { inherit config lib; });
    };
}
