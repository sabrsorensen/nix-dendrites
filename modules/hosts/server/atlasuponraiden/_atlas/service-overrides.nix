{
  config,
  ...
}:
{
  services = {
    # Work around intermittent POSIX shared-memory segment lookup failures
    # (`/PostgreSQL.*` ENOENT) by using SysV dynamic shared memory.
    postgresql.settings.dynamic_shared_memory_type = "sysv";
  };

  users.users.sonos = {
    isSystemUser = true;
    group = "media";
  };
}
