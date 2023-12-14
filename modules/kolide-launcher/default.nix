flake: { config, lib, pkgs, ... }:

let
  inherit (lib) types mkEnableOption mkOption mkIf;
  inherit (flake.packages.x86_64-linux) launcher;
  cfg = config.services.launcher;
in
{
  imports = [];

  options.services.launcher = {
    enable = mkEnableOption ''
      Kolide launcher agent.
    '';
  };

  config = mkIf cfg.enable {
    systemd.services.launcher = {
      description = "The Kolide Launcher";
      after = [ "network.service" "syslog.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ patchelf ];

      preStart = ''
      mkdir -p /var/lib/kolide-k2/k2device-preprod.kolide.com

      if [ ! -d "/etc/kolide-k2" ]; then
        mkdir -p /etc/kolide-k2
        echo -n 'secret' > /etc/kolide-k2/secret

        osquerydPath=${flake.packages.x86_64-linux.launcher}/bin/osqueryd
        tee /etc/kolide-k2/launcher.flags <<EOF
with_initial_runner
autoupdate
transport jsonrpc
hostname k2device-preprod.kolide.com
root_directory /var/lib/kolide-k2/k2device-preprod.kolide.com
osqueryd_path $osquerydPath
enroll_secret_path /etc/kolide-k2/secret
update_channel nightly
debug
EOF
      fi
'';

      serviceConfig = {
        Environment = "PATH=/run/wrappers/bin:/bin:/sbin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
        ExecStart = "${flake.packages.x86_64-linux.launcher}/bin/launcher -config /etc/kolide-k2/launcher.flags";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
