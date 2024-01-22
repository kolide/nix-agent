{ flake }:

let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/nixOS/nixpkgs/archive/23.11.tar.gz";
    sha256 = "sha256:1ndiv385w1qyb3b18vw13991fzb9wg4cl21wglk89grsfsnra41k";
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
    services.xserver.desktopManager.mate.debug = true;

    # This just quiets some log spam we don't care about
    hardware.pulseaudio.enable = true;

    services.kolide-launcher.enable = true;
    system.stateVersion = "23.11";
  };

  enableOCR = true;

  testScript = { nodes, ... }:
    let
      user = nodes.machine.users.users.alice;
      uid = toString user.uid;
      xauthority = "${user.home}/.Xauthority";
      ci = builtins.getEnv "CI";
    in
    ''
      if "${ci}":
        machine.start()

        with subtest("log in to MATE"):
          machine.wait_for_unit("display-manager.service", timeout=120)
          machine.wait_for_file("${xauthority}")
          machine.succeed("xauth merge ${xauthority}")
          machine.wait_until_succeeds("pgrep marco")
          machine.wait_for_window("marco")
          machine.wait_until_succeeds("pgrep mate-panel")
          machine.wait_for_window("Top Panel")
          machine.wait_for_window("Bottom Panel")
          machine.wait_until_succeeds("pgrep caja")
          machine.wait_for_window("Caja")
          machine.sleep(20)
          machine.screenshot("test-screen1.png")

        with subtest("set up secret file"):
          machine.copy_from_host("${./test-secret}", "/etc/kolide-k2/secret")

        with subtest("launcher service runs and is set up correctly"):
          machine.systemctl("stop kolide-launcher.service")
          machine.systemctl("start kolide-launcher.service")
          machine.wait_for_unit("kolide-launcher.service", timeout=120)
          machine.wait_for_file("/var/kolide-k2/k2device.kolide.com/debug.json")
          machine.sleep(60)
          machine.screenshot("test-screen2.png")

        with subtest("osquery runs"):
          machine.wait_until_succeeds("pgrep osqueryd", timeout=30)
          machine.screenshot("test-screen3.png")

        with subtest("launcher desktop runs (test incomplete for now)"):
          machine.wait_for_file("/var/kolide-k2/k2device.kolide.com/kolide.png")
          machine.wait_for_file("/var/kolide-k2/k2device.kolide.com/menu.json")
          machine.screenshot("test-screen4.png")

        with subtest("launcher flare"):
          _, launcher_find_stdout = machine.execute("ls /nix/store | grep kolide-launcher-")
          print(launcher_find_stdout)
          launcher_path = "/nix/store" + launcher_find_stdout.strip() + "/bin/launcher"
          doctor_status, doctor_stdout = machine.execute(launcher_path + " doctor")
          print(doctor_status)
          print(doctor_stdout)
          flare_status, flare_stdout = machine.execute(launcher_path + " flare --save local")
          print(flare_status)
          print(flare_stdout)
          pwd_status, pwd_out = machine.execute("pwd")
          print(pwd_status)
          print(pwd_out)
          ls_status, ls_out = machine.execute("ls ./")
          print(ls_status)
          print(ls_out)
          machine.copy_from_vm("./kolide_agent_flare_report_*.zip", "./")

        with subtest("launcher troubleshooting"):
          root_status, root_stdout = machine.execute("ls -al /var/kolide-k2/k2device-preprod.kolide.com/")
          print(root_status)
          print(root_stdout)

          machine.systemctl("restart kolide-launcher.service")
          machine.sleep(15)
          status, stdout = machine.execute("journalctl --unit=kolide-launcher.service -n 100 --no-pager")
          print(status)
          print(stdout)
          print(machine.get_screen_text())

        machine.shutdown()
    '';
}
