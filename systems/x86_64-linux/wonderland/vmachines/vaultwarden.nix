{
  config ? throw "no imported as a module",
  lib ? throw "no imported as a module",
  domain ? throw "no domain provided",
  ipv4 ? throw "no ipv4 address provided",
  safeDir ? "/persist",
  ...
}:
let
  subdomain = "vault.${domain}";
in
{
  containers = {
    "vaultwarden" = {
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      localAddress = "10.100.0.12";
      hostAddress = ipv4;
      bindMounts = {
        "/run/agenix" = {
          isReadOnly = true;
          hostPath = "/run/agenix";
        };
        "${config.containers."vaultwarden".config.services.vaultwarden.config.DATA_FOLDER}" = {
          isReadOnly = false;
          hostPath = "${safeDir}/vaultwarden";
        };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        users = {
          groups."vmachines" = config.users.groups."vmachines";
          users."vaultwarden" = {
            uid = lib.mkForce config.users.users."vmachines".uid;
            group = lib.mkForce "vmachines";
            isSystemUser = true;
            shell = "/run/current-system/sw/bin/nologin";
          };
        };
        services.vaultwarden = {
          enable = true;
          dbBackend = "sqlite";
          config = {
            DATA_FOLDER = "/var/lib/vaultwarden";
            DOMAIN = "https://${subdomain}";
            ROCKET_ADDRESS = "0.0.0.0";
            ROCKET_PORT = 8000;
            INVITATIONS_ALLOWED = false;
            SHOW_PASSWORD_HINT = false;
            SIGNUPS_ALLOWED = true;
          };
          environmentFile = "/run/agenix/vaultwarden.token";
        };
        networking = {
          hostName = "vaultwarden";
          nameservers = [ config.containers."dnsmasq".localAddress ];
          firewall.allowedTCPPorts = [
            config.containers."vaultwarden".config.services.vaultwarden.config.ROCKET_PORT
          ];
        };
      };
    };

    # ============================= Proxy =============================

    "caddy".config.services.caddy.virtualHosts."${subdomain}".extraConfig = ''
      import default-headers
      import tls

      reverse_proxy http://${config.containers."vaultwarden".localAddress}:${
        toString config.containers."vaultwarden".config.services.vaultwarden.config.ROCKET_PORT
      }
    '';
  };
}
