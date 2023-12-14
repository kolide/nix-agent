{
  description = "Kolide launcher";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.launcher =
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation {
        name = "launcher";
        version = "1.2.1-11-g8c04686";

        src = fetchzip {
          url = "https://dl.kolide.co/kolide/launcher/linux/amd64/launcher-1.2.1-11-g8c04686.tar.gz";
          sha256 = "sha256-sNw+c6gASo8vesJ+KOrNkvKEF4iKA3tM3li3vRYEoPc=";
          name = "launcher";
        };

        osqSrc = fetchzip {
          url = "https://dl.kolide.co/kolide/osqueryd/linux/amd64/osqueryd-5.10.2.tar.gz";
          sha256 = "sha256-z8GNNsAeFptCzPbHs/CFaLrCtuYCXwT5QTJaEAH6ncA=";
          name = "osqueryd";
        };

        nativeBuildInputs = [
          autoPatchelfHook
        ];

        buildInputs = [];

        installPhase = ''
          mkdir -p $out/bin
          cp launcher $out/bin
          cp $osqSrc/osqueryd $out/bin
        '';

        meta = with lib; {
          homepage = "https://www.kolide.com";
          description = "Kolide Endpoint Agent";
          platforms = [ "x86_64-linux" ];
          license = licenses.unfree;
          sourceProvenance = with sourceTypes; [ binaryNativeCode ];
          maintainers = with stdenv.lib.maintainers; [ RebeccaMahany ];
        };
      };

    packages.x86_64-linux.default = self.packages.x86_64-linux.launcher;

    nixosModules.launcher = import ./modules/launcher self;
  };
}
