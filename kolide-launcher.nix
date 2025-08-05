{ autoPatchelfHook
, fetchzip
, lib
, stdenv
}:

stdenv.mkDerivation rec {
  pname = "kolide-launcher";
  version = "1.23.1";

  src = fetchzip {
    url = "https://dl.kolide.co/kolide/launcher/linux/amd64/launcher-${version}.tar.gz";
    sha256 = "sha256-cOppcheWqwHUnOj4ru7fvSyUkNdXLz8w4h+KG1BtLuk=";
    name = "launcher";
  };

  osqSrc = fetchzip {
    url = "https://dl.kolide.co/kolide/osqueryd/linux/amd64/osqueryd-5.18.1.tar.gz";
    sha256 = "sha256-SU8zTTRF64+lv8ADeW/ydPRMDbRKvwCM03rQ+RcbWic=";
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
}
