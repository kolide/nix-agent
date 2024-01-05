{ flake }:

let
  nixpkgs = builtins.fetchTarball "https://github.com/nixOS/nixpkgs/archive/23.05.tar.gz";
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

    with subtest("kolide-launcher service starts"):
      machine.wait_for_unit("kolide-launcher.service")
  '';
}
