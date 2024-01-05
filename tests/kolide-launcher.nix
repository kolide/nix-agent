{ flake }:

let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/nixOS/nixpkgs/archive/23.05.tar.gz";
    sha256 = "sha256:10wn0l08j9lgqcw8177nh2ljrnxdrpri7bp0g7nvrsn9rkawvlbf"; 
  };
  pkgs = import nixpkgs { config = {}; overlays = []; };
in

pkgs.nixosTest {
  name = "kolide-launcher";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      flake.nixosModules.kolide-launcher
    ];
    config = {
      services.kolide-launcher.enable = true;
      system.stateVersion = "23.05";
    };
  };

  testScript = { nodes, ... }: ''
    machine.start()

    with subtest("launcher starts"):
      machine.wait_for_file("/var/lib/kolide-k2/k2device.kolide.com/debug.json")

    with subtest("kolide-launcher service starts"):
      machine.wait_for_unit("kolide-launcher.service")

    machine.shutdown()
  '';
}
