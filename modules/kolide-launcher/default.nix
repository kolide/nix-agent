flake: { config, lib, pkgs, ... }:

let
  inherit (lib) types mkEnableOption mkOption mkIf optional;
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

      # Hard requirements should go in list; optional requirements should be added as optional.
      # Intentionally not included because they aren't supported on Nix:
      # - CrowdStrike (falconctl, falcon-kernel-check)
      # - Carbon Black (repcli)
      # - dnf (related libraries dnf5, libdnf, and microdnf are available, but nothing provides the dnf binary)
      # - x-www-browser (symlink created via `update-alternatives`, which isn't available)
      path = with pkgs; [
        patchelf # Required to auto-update successfully
        systemd # Provides loginctl, systemctl; loginctl required to run desktop
        xdg-utils # Provides xdg-open, required to open browser from notifications and menu bar app
      ]
      ++ optional (builtins.elem apt config.environment.systemPackages) apt
      ++ optional (builtins.elem cryptsetup config.environment.systemPackages) cryptsetup
      ++ optional (builtins.elem coreutils-full config.environment.systemPackages) coreutils-full # Provides echo
      ++ optional (builtins.elem dpkg config.environment.systemPackages) dpkg
      ++ optional (builtins.elem glib config.environment.systemPackages) glib # Provides gsettings
      ++ optional (builtins.elem gnome.gnome-shell config.environment.systemPackages) gnome.gnome-shell # Provides gnome-extensions
      ++ optional (builtins.elem iproute2 config.environment.systemPackages) iproute2 # Provides ip
      ++ optional (builtins.elem libnotify config.environment.systemPackages) libnotify # Provides notify-send
      ++ optional (builtins.elem lsof config.environment.systemPackages) lsof
      ++ optional (builtins.elem nettools config.environment.systemPackages) nettools # Provides ifconfig
      ++ optional (builtins.elem networkmanager config.environment.systemPackages) networkmanager # Provides nmcli
      ++ optional (builtins.elem pacman config.environment.systemPackages) pacman
      ++ optional (builtins.elem procps config.environment.systemPackages) procps # Provides ps
      ++ optional (builtins.elem rpm config.environment.systemPackages) rpm
      ++ optional (builtins.elem xorg.xrdb config.environment.systemPackages) xorg.xrdb # Provides xrdb
      ++ optional (builtins.elem util-linux config.environment.systemPackages) util-linux # Provides lsblk
      ++ optional (builtins.elem zerotierone config.environment.systemPackages) zerotierone # Provides zerotier-cli
      ++ optional (builtins.elem zfs config.environment.systemPackages) zfs # Provides zfs, zpool
      ;

      serviceConfig = {
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
