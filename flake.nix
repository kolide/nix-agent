{
  description = "Kolide launcher";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.kolide-launcher =
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation rec {
        pname = "kolide-launcher";
        version = "1.4.5";

        src = fetchzip {
          url = "https://dl.kolide.co/kolide/launcher/linux/amd64/launcher-${version}.tar.gz";
          sha256 = "sha256-Dg9CvMX56lenrv0fwzbebqj1ktSdKeiPp593bOV6ERg=";
          name = "launcher";
        };

        osqSrc = fetchzip {
          url = "https://dl.kolide.co/kolide/osqueryd/linux/amd64/osqueryd-5.11.0.tar.gz";
          sha256 = "sha256-gUWow5ZmK7AVBJXkOYQdm1C0gGpr2XExAJgKvSJMnGM=";
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
          license = {
            fullName = "The Kolide Enterprise Edition (EE) license";
            url = "https://github.com/kolide/launcher/blob/main/LICENSE";
            free = false;
            redistributable = false;
          };
          sourceProvenance = with sourceTypes; [ binaryNativeCode ];
        };
      };

    packages.x86_64-linux.default = self.packages.x86_64-linux.kolide-launcher;

    nixosModules.kolide-launcher = import ./modules/kolide-launcher self;

    checks.x86_64-linux.kolide-launcher = import ./tests/kolide-launcher.nix { flake = self; };
  };
}
