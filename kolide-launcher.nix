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
          url = "https://dl.kolide.co/kolide/launcher/linux/amd64/launcher-1.27.2.tar.gz";
          sha256 = "sha256-S5+tS8MxatyCNiiBG2oGxnFcqGEn+uaPMa9RSUtkgsU=";
          name = "launcher";
        };
        osqSrc = fetchzip {
          url = "https://dl.kolide.co/kolide/osqueryd/linux/amd64/osqueryd-5.18.1.tar.gz";
          sha256 = "sha256-kozONOHLF+Z36ZSFI4IsRqpYi5A+TDS6qjBdewof83I=";
          name = "osqueryd";
        };
      };

      aarch64-linux = {
        src = fetchzip {
          url = "https://dl.kolide.co/kolide/launcher/linux/arm64/launcher-1.23.1.tar.gz";
          sha256 = "sha256-J490ne3EhFkjNxd/lVgO+V3RXKzwbDHAhg6jtajnHf8=";
          name = "launcher";
        };
        osqSrc = fetchzip {
          url = "https://dl.kolide.co/kolide/osqueryd/linux/arm64/osqueryd-5.18.1.tar.gz";
          sha256 = "sha256-iV/oun27f1mLNcwNr27p+e7sRckl1l9PxuoCTbNmq3w=";
          name = "osqueryd";
        };
      };
    };
in

stdenv.mkDerivation rec {
  pname = "kolide-launcher";
  version = "1.27.2";

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
