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

        with subtest("launcher flare"):
          machine.wait_for_unit("network-online.target")
          machine.wait_for_unit("uwsgi.service")
          machine.wait_for_unit("kolide-launcher.service", timeout=150)
          machine.wait_for_file("/var/kolide-k2/k2device.kolide.com/debug.json")
          _, launcher_find_stdout = machine.execute("ls /nix/store | grep kolide-launcher-")
          machine.execute("/nix/store/" + launcher_find_stdout.strip() + "/bin/launcher flare --save local")

          # copy_from_vm can't take a wildcard path, so find the exact path before copying
          _, flare_ls_out = machine.execute("ls ./kolide_agent_flare_report_*.zip")
          flare_path = "./" + flare_ls_out.strip()
          machine.copy_from_vm(flare_path, "./")

        machine.shutdown()
    '';
}
