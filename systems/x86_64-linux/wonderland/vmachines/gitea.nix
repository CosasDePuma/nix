{
  config ? throw "no imported as a module",
  lib ? throw "no imported as a module",
  domain ? throw "no domain provided",
  ipv4 ? throw "no ipv4 address provided",
  safeDir ? "/persist",
  ...
}:
{
  containers = {
    "gitea" = {
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      localAddress = "10.100.0.10";
      hostAddress = ipv4;
      bindMounts = {
        "${config.containers."gitea".config.services.gitea.stateDir}" = {
          isReadOnly = false;
          hostPath = "${safeDir}/gitea";
        };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        users = {
          groups."vmachines" = config.users.groups."vmachines";
          users."gitea" = {
            uid = lib.mkForce config.users.users."vmachines".uid;
            group = lib.mkForce "vmachines";
            isSystemUser = true;
            shell = "/run/current-system/sw/bin/nologin";
          };
        };
        services.gitea = {
          enable = true;
          user = "gitea";
          group = "gitea";
          database.createDatabase = true;
          settings = {
            server = {
              DOMAIN = "git.${domain}";
              HTTP_ADDR = "0.0.0.0";
              HTTP_PORT = 3000;
              ROOT_URL = "https://${config.containers."gitea".config.services.gitea.settings.server.DOMAIN}";
            };
            session = {
              COOKIE_SECURE = true;
            };
            other = {
              SHOW_FOOTER_VERSION = false;
            };
          };
          dump = {
            enable = true;
            file = "gitea-backup";
            interval = "hourly";
            type = "tar.gz";
          };
        };
        networking = {
          hostName = "gitea";
          firewall.allowedTCPPorts = [ config.containers."gitea".config.services.gitea.settings.server.HTTP_PORT ];
        };
      };
    };
    "traefik".config.services.traefik.dynamicConfigOptions.http = {
      routers."gitea" = {
        rule = "Host(`git.${domain}`)";
        service = "gitea";
      };
      services."gitea".loadBalancer.servers = [
        {
          url = "http://${config.containers."gitea".localAddress}:${
            toString config.containers."gitea".config.services.gitea.settings.server.HTTP_PORT
          }";
        }
      ];
    };
  };
}
