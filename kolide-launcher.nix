{ autoPatchelfHook
, fetchzip
, lib
, stdenv
}:

stdenv.mkDerivation rec {
  pname = "kolide-launcher";
  version = "1.9.4";

  src = fetchzip {
    url = "https://dl.kolide.co/kolide/launcher/linux/amd64/launcher-${version}.tar.gz";
    sha256 = "sha256-5zDu8WQyM4SM8ByvTYU1QR6zdxU/RJJWHCoVyceuTTA=";
    name = "launcher";
  };

  osqSrc = fetchzip {
    url = "https://dl.kolide.co/kolide/osqueryd/linux/amd64/osqueryd-5.12.2.tar.gz";
    sha256 = "sha256-5o7zynfo5ynan900pKh9hTRlkh2wVgr7a68HFjc5zYw=";
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
