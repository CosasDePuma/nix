{
  config ? throw "no imported as a module",
  domain ? throw "no domain provided",
  ipv4 ? throw "no ipv4 address provided",
  ...
}:
let
  subdomain = "send.${domain}";
in
{
  containers = {
    "send" = {
      localAddress = "10.100.0.20";
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      hostAddress = ipv4;
      config = {

        # ============================= Config =============================

        system.stateVersion = config.system.stateVersion;
        services.send = {
          enable = true;
          host = "0.0.0.0";
          port = 1443;
          openFirewall = true;
        };
        networking.hostName = "send";
      };
    };

    # ============================= Proxy =============================

    "caddy".config.services.caddy.virtualHosts."${subdomain}".extraConfig = ''
      reverse_proxy http://${config.containers."send".localAddress}:${
        toString config.containers."send".config.services.send.port
      }

      tls /var/lib/acme/${domain}/cert.pem /var/lib/acme/${domain}/key.pem {
        protocols tls1.2 tls1.3
      }
    '';
  };
}
