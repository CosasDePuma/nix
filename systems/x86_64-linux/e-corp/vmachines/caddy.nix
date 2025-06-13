{
  config ? throw "no imported as a module",
  lib ? throw "no imported as a module",
  ipv4 ? throw "no ipv4 address provided",
  safeDir ? "/persist",
  ...
}:
{
  containers = {
    "caddy" = {
      localAddress = "10.100.0.3";
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      hostAddress = ipv4;
      bindMounts = {
        "/run/agenix" = {
          isReadOnly = true;
          hostPath = "/run/agenix";
        };
        "/var/lib/acme" = {
          isReadOnly = true;
          hostPath = "/var/lib/acme";
        };
        "${config.containers."caddy".config.services.caddy.dataDir}" = {
          isReadOnly = false;
          hostPath = "${safeDir}/caddy";
        };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        users = {
          users."caddy" = {
            uid = lib.mkForce config.users.users."vmachines".uid;
            group = "caddy";
          };
          groups."caddy".gid = lib.mkForce config.users.groups."vmachines".gid;
        };

        # --- caddy

        services.caddy = {
          enable = true;
          group = "caddy";
          enableReload = true;
          logFormat = "level INFO";
          globalConfig = ''
            metrics {
              per_host
            }
          '';
        };
        networking = {
          hostName = "caddy";
          firewall.allowedTCPPorts = [ 443 ];
        };
      };
    };
  };
}
