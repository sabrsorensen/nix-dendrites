{
  # Shared between dualboot.nix (hand-mounted, coexisting with SteamOS) and
  # singleboot.nix (disko, wipes the disk) so the two boot modes' subvolume
  # layouts can't silently drift apart.
  mountOptions = [
    "compress=zstd"
    "noatime"
  ];
  mountpoints = {
    "@root" = "/";
    "@home" = "/home";
    "@nix" = "/nix";
    "@steam" = "/srv/steam-library";
  };
}
