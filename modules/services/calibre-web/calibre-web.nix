{ ... }:
{
  flake.modules.nixos.calibre-web =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.calibreWeb;
      booksRoot = "${config.my.media.dataRoot}/books";
    in
    {
      options.my.calibreWeb = {
        hostName = lib.mkOption {
          type = lib.types.str;
          default = "books";
          description = "Subdomain (below {$DOMAIN}) Calibre-Web is served on.";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 8083;
          description = "Loopback port Calibre-Web listens on behind Caddy.";
        };
        libraryDir = lib.mkOption {
          type = lib.types.str;
          default = "${booksRoot}/library";
          description = "Calibre library (metadata.db + book files); created empty if missing.";
        };
        importDir = lib.mkOption {
          type = lib.types.str;
          default = "${booksRoot}/import";
          description = ''
            Drop folder watched by a systemd path unit. Files (recursively) are
            added with `calibredb add` once they have stopped changing, then
            removed. Anything calibredb doesn't accept is moved to failedImportDir.
          '';
        };
        failedImportDir = lib.mkOption {
          type = lib.types.str;
          default = "${booksRoot}/import-failed";
          description = "Where unimportable drop-folder files are moved (kept outside importDir so the path unit doesn't re-trigger on them).";
        };
      };

      options.my.host.services.calibreWeb = lib.mkEnableOption "Calibre-Web ebook library";

      config = lib.mkIf config.my.host.services.calibreWeb (
        import ./_calibre-web.nix (args // { inherit cfg booksRoot; })
      );
    };
}
