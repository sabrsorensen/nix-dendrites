{ inputs, lib, ... }:
let
  supportedSystem = "x86_64-linux";
  mkArmory =
    pkgs:
    let
      runtimePkgs = inputs.armory-runtime-nixpkgs.legacyPackages.${supportedSystem};
      python = runtimePkgs.python27.withPackages (ps: [
        ps.psutil
        ps.pyqt4
      ]);
    in
    pkgs.stdenv.mkDerivation rec {
      pname = "armory";
      version = "0.96.5";
      src = pkgs.fetchurl {
        url = "https://github.com/goatpig/BitcoinArmory/releases/download/v${version}/armory_${version}_amd64_gcc7.2.deb";
        hash = "sha256-yDNH1oDVz2TkSBB3+EcEB0x9gpaBcDJRm5kGvExdBfo=";
      };
      nativeBuildInputs = [
        pkgs.autoPatchelfHook
        pkgs.dpkg
        pkgs.makeWrapper
      ];
      buildInputs = [ pkgs.stdenv.cc.cc.lib ];
      dontUnpack = true;
      installPhase = ''
        dpkg-deb -x "$src" "$out"
        substituteInPlace "$out/usr/lib/armory/SDM.py" \
          --replace-fail "pargs.append('--db-type=\"' + ARMORY_DB_TYPE + '\"')" "pargs.append('--db-type=' + ARMORY_DB_TYPE)" \
          --replace-fail "pargs.append('--satoshi-datadir=\"' + blocksdir + '\"')" "pargs.append('--satoshi-datadir=' + blocksdir)" \
          --replace-fail "pargs.append('--datadir=\"' + dataDir + '\"')" "pargs.append('--datadir=' + dataDir)" \
          --replace-fail "pargs.append('--dbdir=\"' + dbDir + '\"')" "pargs.append('--dbdir=' + dbDir)" \
          --replace-fail "pargs.append('--satoshi-datadir=' + blocksdir)" "pargs.append('--satoshi-datadir=' + self.satoshiHome)"
        mkdir -p "$out/bin" "$out/share/applications" "$out/share/pixmaps"
        ln -s "$out/usr/bin/ArmoryDB" "$out/bin/ArmoryDB"
        cat > "$out/bin/armory" <<'EOF'
        #!${pkgs.runtimeShell}
        export PATH="${
          lib.makeBinPath [
            runtimePkgs.bitcoind
            pkgs.coreutils
            pkgs.glibc.bin
            pkgs.procps
            pkgs.util-linux
            pkgs.xdg-utils
          ]
        }:$out/bin:$out/usr/bin:''${PATH}"
        if [ -z "''${HOME:-}" ] || [ "''${HOME}" = "/homeless-shelter" ]; then
          HOME="$(${pkgs.glibc.bin}/bin/getent passwd "$(${pkgs.coreutils}/bin/id -un)" | ${pkgs.coreutils}/bin/cut -d: -f6 || true)"
          HOME="''${HOME:-/home/$(${pkgs.coreutils}/bin/id -un)}"
          export HOME
        fi
        ${pkgs.coreutils}/bin/mkdir -p "''${HOME}/.bitcoin/blocks"
        cd "$out/usr/share/armory"
        exec ${python}/bin/python2 "$out/usr/lib/armory/ArmoryQt.py" "$@"
        EOF
        substituteInPlace "$out/bin/armory" --replace-fail '$out' "$out"
        chmod +x "$out/bin/armory"
        cp "$out/bin/armory" "$out/bin/armory-offline"
        substituteInPlace "$out/bin/armory-offline" --replace-fail 'ArmoryQt.py" "$@"' 'ArmoryQt.py" --offline "$@"'
        chmod +x "$out/bin/armory-offline"
        cat > "$out/share/applications/armory.desktop" <<EOF
        [Desktop Entry]
        Name=Armory
        Comment=Advanced Bitcoin Wallet Management Software
        Exec=armory
        Icon=armory
        Terminal=false
        Type=Application
        Categories=Office;Finance;
        EOF
        ln -s "$out/usr/share/armory/img/preferences256.png" "$out/share/pixmaps/armory.png"
      '';
      meta = {
        description = "Advanced Bitcoin wallet management software";
        mainProgram = "armory";
        platforms = [ supportedSystem ];
      };
    };
in
{
  perSystem = { pkgs, system, ... }: {
    packages = lib.optionalAttrs (system == supportedSystem) {
      armory = mkArmory pkgs;
    };
  };

  flake.modules.nixos.armory =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.armory {
      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.system == supportedSystem;
          message = "Armory is only supported on x86_64-linux because upstream ships an amd64 release and requires Python 2/PyQt4.";
        }
      ];
      environment.systemPackages = [
        inputs.self.packages.${supportedSystem}.armory
        inputs.armory-runtime-nixpkgs.legacyPackages.${supportedSystem}.bitcoind
      ];
    };
}
