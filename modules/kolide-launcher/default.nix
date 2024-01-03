flake: { config, lib, pkgs, ... }:

let
  inherit (lib) types mkEnableOption mkOption mkIf;
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
      default = "/var/lib/kolide-k2/k2device.kolide.com";
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
  };

  config = mkIf cfg.enable {
    systemd.services.kolide-launcher = {
      description = "The Kolide Launcher";
      after = [ "network.service" "syslog.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ patchelf ];

      serviceConfig = {
        Environment = "PATH=/run/wrappers/bin:/bin:/sbin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
        ExecStart = ''
          ${flake.packages.x86_64-linux.kolide-launcher}/bin/launcher \
            --hostname ${cfg.kolideHostname} \
            --root_directory ${cfg.rootDirectory} \
            --osqueryd_path ${flake.packages.x86_64-linux.kolide-launcher}/bin/osqueryd \
            --enroll_secret_path ${cfg.enrollSecretDirectory}/secret \
            --update_channel ${cfg.updateChannel} \
            --transport jsonrpc \
            --autoupdate
        '';
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
