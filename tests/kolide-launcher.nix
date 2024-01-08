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

    users.users.alice = {
      isNormalUser = true;
      description = "Alice Test";
      password = "alicetest";
      uid = 1000;
    };

    services.xserver.enable = true;
    services.xserver.displayManager = {
      lightdm.enable = true;
      autoLogin = {
        enable = true;
        user = "alice";
      };
    };
    services.xserver.desktopManager.mate.enable = true;

    # This just quiets some log spam we don't care about
    hardware.pulseaudio.enable = true;

    services.kolide-launcher.enable = true;
    system.stateVersion = "23.05";
  };

  testScript = { nodes, ... }:
    let
      user = nodes.machine.users.users.alice;
    in
    ''
      machine.start()

      # TODO: currently launcher will shut itself down if its secret file doesn't exist,
      # so we don't get all the way through setup and launcher doesn't stay running.
      # In the future, we'll want to validate setup and that the service is running.

      with subtest("kolide-launcher service starts"):
        machine.wait_for_unit("kolide-launcher.service")
        machine.sleep(10)
        machine.systemctl("stop kolide-launcher.service")

      with subtest("launcher set up correctly"):
        machine.wait_for_file("/var/lib/kolide-k2/k2device.kolide.com/debug.json")

      with subtest("get a screenshot"):
        machine.wait_for_unit("display-manager.service")

        machine.wait_for_file("${user.home}/.Xauthority")
        machine.succeed("xauth merge ${user.home}/.Xauthority")

        machine.wait_until_succeeds("pgrep marco")
        machine.wait_for_window("marco")
        machine.wait_until_succeeds("pgrep mate-panel")
        machine.wait_for_window("Top Panel")
        machine.wait_for_window("Bottom Panel")
        machine.wait_until_succeeds("pgrep caja")
        machine.wait_for_window("Caja")
        machine.sleep(20)
        machine.screenshot("test.png")

      machine.shutdown()
    '';
}
