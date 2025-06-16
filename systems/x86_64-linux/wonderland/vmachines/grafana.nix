{
  config ? throw "no imported as a module",
  lib ? throw "no imported as a module",
  domain ? throw "no domain provided",
  ipv4 ? throw "no ipv4 address provided",
  safeDir ? "/persist",
  ...
}:
let
  subdomain = "dashboard.${domain}";
in
{
  containers = {
    "grafana" = {
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      localAddress = "10.100.0.5";
      hostAddress =
        (builtins.head
          config.networking.interfaces.${builtins.head (builtins.attrNames config.networking.interfaces)}.ipv4.addresses
        ).address;
      bindMounts = {
        "/var/lib/grafana" = {
          isReadOnly = false;
          hostPath = "${safeDir}/grafana";
        };
      };
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        users = {
          groups."grafana" = { inherit (config.users.groups."vmachines") gid; };
          users."grafana".uid = lib.mkForce config.users.users."vmachines".uid;
        };
        services.grafana = {
          enable = true;
          settings = {
            server = {
              http_addr = "0.0.0.0";
              http_port = 3000;
              domain = subdomain;
              serve_from_sub_path = true;
            };
          };
        };
        networking = {
          hostName = "grafana";
          nameservers = [ config.containers."dnsmasq".localAddress ];
          firewall.allowedTCPPorts = [
            config.containers."grafana".config.services.grafana.settings.server.http_port
          ];
        };
      };
    };

    # ============================= Proxy =============================

    "caddy".config.services.caddy.virtualHosts."${subdomain}".extraConfig = ''
      import defaults
      reverse_proxy http://${config.containers."grafana".localAddress}:${
        toString config.containers."grafana".config.services.grafana.settings.server.http_port
      }
    '';
  };
}
