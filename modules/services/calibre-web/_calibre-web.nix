{
  config,
  lib,
  pkgs,
  cfg,
  booksRoot,
  ...
}:
let
  calibre = config.services.calibre-web.calibrePackage;
  user = config.services.calibre-web.user;
  group = config.services.calibre-web.group;

  ebookExtensions = [
    "azw"
    "azw1"
    "azw3"
    "azw4"
    "mobi"
    "prc"
    "pdb"
    "epub"
    "kepub"
    "pdf"
    "djvu"
    "cbz"
    "cbr"
    "cb7"
    "cbc"
    "fb2"
    "fbz"
    "lit"
    "lrf"
    "rtf"
    "docx"
    "odt"
    "txt"
    "txtz"
    "htmlz"
    "chm"
    "snb"
    "tcr"
    "pml"
    "rb"
  ];

  # calibre-web refuses to start without a metadata.db and can't create one;
  # `calibredb list` against a missing library creates an empty one.
  initLibrary = pkgs.writeShellApplication {
    name = "calibre-library-init";
    runtimeInputs = [ calibre ];
    text = ''
      library=${lib.escapeShellArg cfg.libraryDir}
      if [ ! -f "$library/metadata.db" ]; then
        echo "Creating empty Calibre library in $library"
        calibredb --with-library "$library" list >/dev/null
      fi
    '';
  };

  # calibredb exits 0 even on failure, so success is judged from its output.
  importBooks = pkgs.writeShellApplication {
    name = "calibre-import";
    runtimeInputs = [
      calibre
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
    ];
    text = ''
      library=${lib.escapeShellArg cfg.libraryDir}
      import=${lib.escapeShellArg cfg.importDir}
      failed=${lib.escapeShellArg cfg.failedImportDir}
      settle=30

      # Wait for in-flight copies (e.g. over Samba) to finish: nothing in the
      # drop folder may have changed within the last $settle seconds.
      while [ -n "$(find "$import" -mindepth 1 -newermt "@$(( $(date +%s) - settle ))" -print -quit)" ]; do
        sleep 10
      done

      find "$import" -mindepth 1 -type f -print0 | while IFS= read -r -d "" file; do
        case "$(basename "$file")" in
          .DS_Store | ._* | Thumbs.db | desktop.ini)
            rm -f "$file"
            continue
            ;;
        esac

        # calibredb happily "adds" any file (covers, .opf sidecars, KFX it
        # can't read), so only hand it formats Calibre can actually use.
        extension=''${file##*.}
        case "''${extension,,}" in
          ${lib.concatStringsSep " | " ebookExtensions})
            output=$(calibredb --with-library "$library" add --automerge=ignore "$file" 2>&1) || true
            ;;
          *)
            output="unsupported file extension: .$extension"
            ;;
        esac
        if grep -qE '^(Added|Merged) book ids:|already exist in the database' <<<"$output"; then
          echo "imported: $file"
          rm -f "$file"
        else
          relative=''${file#"$import"/}
          destination="''${failed:?}/$relative"
          mkdir -p "$(dirname "$destination")"
          mv -f "$file" "$destination"
          echo "FAILED (moved to $destination): $file" >&2
          printf '%s\n' "$output" >&2
        fi
      done

      find "''${import:?}" -mindepth 1 -type d -empty -delete
    '';
  };
in
{
  my.localDns.records = [ { hostname = cfg.hostName; } ];
  my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
    ''
      reverse_proxy /* 127.0.0.1:${toString cfg.port}
    ''
  ];

  # Group `media` + setgid so the library and drop folder are reachable via
  # the Atlas `media` Samba share (sam is in `media`).
  systemd.tmpfiles.settings."10-calibre-books" =
    lib.genAttrs
      [
        booksRoot
        cfg.libraryDir
        cfg.importDir
        cfg.failedImportDir
      ]
      (_: {
        d = {
          inherit user group;
          mode = "2775";
        };
      });

  services.calibre-web = {
    enable = true;
    group = "media";
    listen = {
      ip = "127.0.0.1";
      inherit (cfg) port;
    };
    options = {
      calibreLibrary = cfg.libraryDir;
      enableBookUploading = true;
      enableBookConversion = true;
    };
  };

  systemd.services.calibre-library-init = {
    description = "Create the Calibre library used by Calibre-Web if it does not exist";
    before = [ "calibre-web.service" ];
    requiredBy = [ "calibre-web.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    environment = {
      HOME = "/var/lib/calibre-import";
      CALIBRE_CONFIG_DIRECTORY = "/var/lib/calibre-import/config";
      QT_QPA_PLATFORM = "offscreen";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = user;
      Group = group;
      UMask = "0002";
      StateDirectory = "calibre-import";
      ExecStart = lib.getExe initLibrary;
    };
  };

  systemd.paths.calibre-import = {
    description = "Watch the Calibre drop folder for new books";
    wantedBy = [ "paths.target" ];
    pathConfig.DirectoryNotEmpty = cfg.importDir;
  };

  systemd.services.calibre-import = {
    description = "Import books from the Calibre drop folder";
    after = [ "calibre-library-init.service" ];
    requires = [ "calibre-library-init.service" ];
    environment = {
      HOME = "/var/lib/calibre-import";
      CALIBRE_CONFIG_DIRECTORY = "/var/lib/calibre-import/config";
      QT_QPA_PLATFORM = "offscreen";
    };
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = group;
      UMask = "0002";
      StateDirectory = "calibre-import";
      ExecStart = lib.getExe importBooks;
      # Files dropped over Samba are owned by sam, often in sam-owned 0755
      # subdirectories; without DAC override the importer couldn't delete or
      # move them, leaving the folder non-empty and the path unit re-firing.
      AmbientCapabilities = [ "CAP_DAC_OVERRIDE" ];
      CapabilityBoundingSet = [ "CAP_DAC_OVERRIDE" ];
      ProtectSystem = "strict";
      ReadWritePaths = [ booksRoot ];
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
    };
  };
}
