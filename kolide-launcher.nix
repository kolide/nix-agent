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
          url = "https://dl.kolide.co/kolide/launcher/linux/amd64/launcher-1.17.0.tar.gz";
          sha256 = "sha256-SjUcNX1kQhI7ovhf6RhiAib+kR2R4QiHft7LSljU21k=";
          name = "launcher";
        };
        osqSrc = fetchzip {
          url = "https://dl.kolide.co/kolide/osqueryd/linux/amd64/osqueryd-5.16.0.tar.gz";
          sha256 = "sha256-SU8zTTRF64+lv8ADeW/ydPRMDbRKvwCM03rQ+RcbWic=";
          name = "osqueryd";
        };
      };

      aarch64-linux = {
        src = fetchzip {
          url = "https://dl.kolide.co/kolide/launcher/linux/arm64/launcher-1.17.0-8-g5039a8f7.tar.gz";
          sha256 = "sha256-nn6OWoeVcsdefey4fYB8zmUpQAUwUs5sNffa5O+cFf4=";
          name = "launcher";
        };
        osqSrc = fetchzip {
          url = "https://dl.kolide.co/kolide/osqueryd/linux/arm64/osqueryd-5.16.0.tar.gz";
          sha256 = "sha256-cBV1a0rU3jX+Y1AIykcSTpTDT47dpvSuNZ0lk8y/6F8=";
          name = "osqueryd";
        };
      };
    };
in

stdenv.mkDerivation rec {
  pname = "kolide-launcher";
  version = "1.12.3";

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
