flake: { config, lib, pkgs, ... }:

let
  inherit (lib) types mkEnableOption mkOption mkIf optional strings;
  inherit (flake.packages.x86_64-linux) kolide-launcher;
  cfg = config.services.kolide-launcher;
in
{
  imports = [];

  options.services.kolide-launcher = {
    enable = mkEnableOption ''
      Kolide launcher agent.
    '';

    kolideHostname = mkOption {
      type = types.str;
      default = "k2device.kolide.com";
      description = ''
        The hostname for the Kolide device management server.
      '';
    };

    rootDirectory = mkOption {
      type = types.path;
      default = "/var/kolide-k2/k2device.kolide.com";
      description = ''
        The path to the directory that will hold launcher-related data,
        including logs, databases, and autoupdates.
      '';
    };

    enrollSecretDirectory = mkOption {
      type = types.path;
      default = "/etc/kolide-k2";
      description = ''
        The path to the directory where the enrollment secret lives.
      '';
    };

    updateChannel = mkOption {
      type = types.str;
      default = "stable";
      description = ''
        Which release channel the launcher installation should use when autoupdating
        itself and its osquery installation: one of stable, nightly, beta, or alpha.
      '';
    };

    autoupdateInterval = mkOption {
      type = types.str;
      default = "1h";
      description = ''
        The interval to check for launcher and osqueryd updates.
      '';
    };

    autoupdaterInitialDelay = mkOption {
      type = types.str;
      default = "1h";
      description = ''
        Initial autoupdater subprocess delay.
      '';
    };

    insecureTransport = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Do not use TLS for transport layer.
      '';
    };

    insecureTLS = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Do not verify TLS certs for outgoing connections.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.kolide-launcher = {
      description = "The Kolide Launcher";
      after = [ "network.service" "syslog.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ patchelf ];

      serviceConfig = {
        # The Kolide agent needs to be able to find various executables by looking them up in PATH.
        # We cannot hardcode a list of packages in systemd.services.kolide-launcher.path because future
        # autoupdated versions of launcher may need to access new executables not listed in this originally-installed
        # module. So, until we have a better option, we give the kolide-launcher unit access to the symlinks
        # in `/run/current-system/sw/bin` and other likely locations that will allow it to find software inside the Nix store.
        Environment = "PATH=/run/wrappers/bin:/bin:/sbin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:${pkgs.patchelf}/bin";
        ExecStart = strings.concatStringsSep " " ([
            "${flake.packages.x86_64-linux.kolide-launcher}/bin/launcher"
            "--hostname ${cfg.kolideHostname}"
            "--root_directory ${cfg.rootDirectory}"
            "--osqueryd_path ${flake.packages.x86_64-linux.kolide-launcher}/bin/osqueryd"
            "--enroll_secret_path ${cfg.enrollSecretDirectory}/secret"
            "--update_channel ${cfg.updateChannel}"
            "--transport jsonrpc"
            "--autoupdate"
            "--autoupdate_interval ${cfg.autoupdateInterval}"
            "--autoupdater_initial_delay ${cfg.autoupdaterInitialDelay}"
          ]
            ++ optional cfg.insecureTransport "--insecure_transport"
            ++ optional cfg.insecureTLS "--insecure"
          );
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.rootDirectory}                0755 - -"
      "d ${cfg.enrollSecretDirectory}        0755 - -"
      "z ${cfg.enrollSecretDirectory}/secret 0600 - -"
    ];
  };
}
