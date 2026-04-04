{
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.extraSetup = ''
    find "$out/share/man" \
        -mindepth 1 -maxdepth 1 \
        -not -name "man[1-8]" \
        -exec rm -r "{}" ";"
  '';

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
}
