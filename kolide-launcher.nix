{ autoPatchelfHook
, fetchzip
, lib
, stdenv
}:

let
  inherit (stdenv.hostPlatform) system;
  sources =
    {
      x86_64-linux = {
        src = fetchzip {
          url = "https://dl.kolide.co/kolide/launcher/linux/amd64/launcher-1.30.2.tar.gz";
          sha256 = "sha256-bLnx3qbkWKeK1/4kmsq2j9CBQtJiIgGyFLxk15XMDLQ=";
          name = "launcher";
        };
        osqSrc = fetchzip {
          url = "https://dl.kolide.co/kolide/osqueryd/linux/amd64/osqueryd-5.20.0.tar.gz";
          sha256 = "sha256-CAsykpLwHbLnPRiR1uyUL/6JSwbVlabt/Q6D0i3jKqo=";
          name = "osqueryd";
        };
      };

      aarch64-linux = {
        src = fetchzip {
          url = "https://dl.kolide.co/kolide/launcher/linux/arm64/launcher-1.30.2.tar.gz";
          sha256 = "sha256-t1rPpCiuOiiOSqIVXLwun4YSwqad53sxtIbs+5wUYV4=";
          name = "launcher";
        };
        osqSrc = fetchzip {
          url = "https://dl.kolide.co/kolide/osqueryd/linux/arm64/osqueryd-5.20.0.tar.gz";
          sha256 = "sha256-i+EBmCLckfcVsXT0FD1GKAk9+8PWg9LuYv61xUuhtqk=";
          name = "osqueryd";
        };
      };
    };
in

stdenv.mkDerivation rec {
  pname = "kolide-launcher";
  version = "1.30.2";

  src = sources.${system}.src;
  osqSrc = sources.${system}.osqSrc;

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
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    license = {
      fullName = "The Kolide Enterprise Edition (EE) license";
      url = "https://github.com/kolide/launcher/blob/main/LICENSE";
      free = false;
      redistributable = false;
    };
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
