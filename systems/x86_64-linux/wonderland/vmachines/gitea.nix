{
  config ? throw "no imported as a module",
  lib ? throw "no imported as a module",
  domain ? throw "no domain provided",
  ipv4 ? throw "no ipv4 address provided",
  safeDir ? "/persist",
  ...
}:
let
  subdomain = "git.${domain}";
in

{
  containers = {
    "gitea" = {
      localAddress = "10.100.0.10";
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
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

        # --- gitea

        services.gitea = {
          enable = true;
          user = "gitea";
          group = "gitea";
          appName = "Wonderland Code";
          database.createDatabase = true;
          settings = {
            "actions" = {
              ENABLED = false;
            };
            "cron" = {
              sync_external_users = false;
            };
            "picture" = {
              DISABLE_GRAVATAR = true;
            };
            "repository" = {
              DEFAULT_PRIVATE = true;
            };
            "server" = {
              DOMAIN = subdomain;
              HTTP_ADDR = "0.0.0.0";
              HTTP_PORT = 3000;
              ROOT_URL = "https://${config.containers."gitea".config.services.gitea.settings.server.DOMAIN}";
            };
            "service" = {
              DISABLE_REGISTRATION = true;
              DISABLE_SSH = false;
            };
            "session" = {
              COOKIE_SECURE = true;
            };
            "other" = {
              SHOW_FOOTER_VERSION = false;
            };
            "ui" = {
              DEFAULT_THEME = "gitea-dark";
              SHOW_USER_EMAIL = false;
              THEMES = "auto,gitea-light,gitea-dark";
            };
            "ui.meta" = {
              AUTHOR = "Unicorns and Goblins";
              DESCRIPTION = "Wonderland's Gitea instance";
            };
          };
          dump = {
            enable = true;
            file = "gitea-backup.tar";
            interval = "hourly";
            type = "tar";
          };
        };
        networking = {
          hostName = "gitea";
          firewall.allowedTCPPorts = [
            config.containers."gitea".config.services.gitea.settings.server.HTTP_PORT
          ];
        };
      };
    };

    # ============================= Proxy =============================

    "caddy".config.services.caddy.virtualHosts."${subdomain}".extraConfig = ''
      import default-headers
      import tls

      reverse_proxy http://${config.containers."gitea".localAddress}:${
        toString config.containers."gitea".config.services.gitea.settings.server.HTTP_PORT
      }
    '';
  };
}
