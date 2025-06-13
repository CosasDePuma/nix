{
  config ? throw "no imported as a module",
  lib ? throw "no imported as a module",
  domain ? throw "no domain provided",
  ipv4 ? throw "no ipv4 address provided",
  safeDir ? "/persist",
  ...
}:
let
  subdomain = "metrics.${domain}";
in
{
  containers = {
    "prometheus" = {
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      localAddress = "10.100.0.5";
      hostAddress =
        (builtins.head
          config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses
        ).address;
      bindMounts = {
        "/var/lib/prometheus2/data" = {
          isReadOnly = false;
          hostPath = "${safeDir}/prometheus";
        };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        users = {
          users."prometheus".uid = lib.mkForce config.users.users."vmachines".uid;
          groups."prometheus".gid = lib.mkForce config.users.groups."vmachines".gid;
        };
        services.prometheus = {
          enable = true;
          listenAddress = "0.0.0.0";
          port = 8080;
          globalConfig = {
            scrape_interval = "15s";
          };
          scrapeConfigs = [
            {
              job_name = "endlessh";
              scheme = "http";
              static_configs = [
                {
                  targets = [
                    "${config.containers."endlessh".localAddress}:${
                      toString config.containers."endlessh".config.services.endlessh-go.prometheus.port
                    }"
                  ];
                }
              ];
            }
            {
              job_name = "wg-easy";
              scheme = "https";
              static_configs = [
                {
                  targets = [
                    "vpn.${domain}:443"
                  ];
                }
              ];
            }
          ];
        };
        networking = {
          hostName = "prometheus";
          nameservers = [ config.containers."dnsmasq".localAddress ];
          firewall.allowedTCPPorts = [ config.containers."prometheus".config.services.prometheus.port ];
        };
      };
    };

    # ============================= Proxy =============================

    "caddy".config.services.caddy.virtualHosts."${subdomain}".extraConfig = ''
      reverse_proxy http://${config.containers."prometheus".localAddress}:${
        toString config.containers."prometheus".config.services.prometheus.port
      }

      tls /var/lib/acme/${domain}/cert.pem /var/lib/acme/${domain}/key.pem {
        protocols tls1.2 tls1.3
      }
    '';
  };
}
