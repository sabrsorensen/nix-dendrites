{
  systemdInhibit,
  ...
}:
{
  inhibitSleep = ''
    echo "🔒 Inhibiting sleep for: $argv"
    echo -ne "\033]0;$argv\007"
    ${systemdInhibit} --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who="$USER" --why=nixos-deployment --mode=block $argv
  '';
}
