{ flake }:

let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/nixOS/nixpkgs/archive/24.11.tar.gz";
    sha256 = "sha256:1gx0hihb7kcddv5h0k7dysp2xhf1ny0aalxhjbpj2lmvj7h9g80a";
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

    system.stateVersion = "24.11";

    # Launcher setup
    services.kolide-launcher.enable = true;
    services.kolide-launcher.kolideHostname = "app.kolide.test:80";
    services.kolide-launcher.insecureTransport = true;
    services.kolide-launcher.insecureTLS = true;

    # Add a (test) secret
    environment.etc."kolide-k2/secret" = {
      mode = "0600";
      text = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMDAwIiwibmFtZSI6ImFsaWNlIiwiaWF0IjoxNzA2MTkzNzYxLCJvcmdhbml6YXRpb24iOiJ0ZXN0LXRlbmFudCJ9.KaZlRr0_XYhopgFvfRqxlEl71cCbqW16pG9sdyFNZrs";
    };

    # Set up mock agent server locally
    networking.extraHosts = "127.0.0.1 app.kolide.test";
    services.uwsgi = {
      enable = true;
      plugins = [ "python3" ];
      capabilities = [ "CAP_NET_BIND_SERVICE" ];
      instance.type = "emperor";

      instance.vassals.agentserver = {
        type = "normal";
        module = "wsgi:application";
        http = ":80";
        http-timeout = 30;
        cap = "net_bind_service";
        pythonPackages = self: [ self.flask ];
        chdir = pkgs.writeTextDir "wsgi.py" (builtins.readFile ./agentserver.py);
      };
    };
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

        with subtest("why is backdoor.service not running"):
          machine.sleep(60)
          machine.systemctl("status backdoor.service")

        with subtest("mock agent server starts up"):
          machine.wait_for_unit("network-online.target")
          machine.wait_for_unit("uwsgi.service")
          machine.wait_until_succeeds("curl --fail http://app.kolide.test/version", timeout=60)

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

        with subtest("launcher service runs and is set up correctly"):
          # Wait a little bit to be sure and then perform a restart now that we're logged in,
          # so that launcher can register with systray correctly
          machine.sleep(20)
          machine.systemctl("restart kolide-launcher.service")
          machine.wait_for_unit("kolide-launcher.service", timeout=60)
          machine.wait_for_file("/var/kolide-k2/k2device.kolide.com/debug.json")
          machine.sleep(30)
          machine.screenshot("test-screen2.png")

        with subtest("osquery runs"):
          machine.wait_until_succeeds("pgrep osqueryd", timeout=30)
          machine.screenshot("test-screen3.png")

        with subtest("launcher desktop runs"):
          machine.wait_for_file("/var/kolide-k2/k2device.kolide.com/kolide.png")
          machine.wait_for_file("/var/kolide-k2/k2device.kolide.com/menu.json")
          machine.screenshot("test-screen4.png")
          # Confirm that a launcher desktop process is spawned for the user
          machine.wait_until_succeeds("pgrep -U ${uid} launcher", timeout=120)
          machine.screenshot("test-screen5.png")

        with subtest("launcher flare"):
          _, launcher_find_stdout = machine.execute("ls /nix/store | grep kolide-launcher-")
          machine.execute("/nix/store/" + launcher_find_stdout.strip() + "/bin/launcher flare --save local")

          # copy_from_vm can't take a wildcard path, so find the exact path before copying
          _, flare_ls_out = machine.execute("ls ./kolide_agent_flare_report_*.zip")
          flare_path = "./" + flare_ls_out.strip()
          machine.copy_from_vm(flare_path, "./")

        machine.shutdown()
    '';
}
