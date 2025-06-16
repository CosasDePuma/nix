{
  config ? throw "no imported as a module",
  domain ? throw "no domain provided",
  ipv4 ? throw "no ipv4 address provided",
  ...
}:
{
  containers."dnsmasq" = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    localAddress = "10.100.0.2";
    hostAddress = ipv4;
    config = {

      # ============================= Config =============================

      system.stateVersion = config.system.stateVersion;
      services.dnsmasq = {
        enable = true;
        resolveLocalQueries = false;
        settings = {
          address = [ "/${domain}/${config.containers."caddy".localAddress}" ];
          bogus-priv = true;
          bind-interfaces = true;
          cache-size = 1000;
          domain-needed = true;
          interface = [
            "lo"
            "eth0"
          ];
          min-cache-ttl = 300;
          no-resolv = true;
          port = 53;
          rebind-domain-ok = "|lan";
          server = config.networking.nameservers;
          stop-dns-rebind = true;
          strict-order = true;
        };
      };
      networking = {
        hostName = "dnsmasq";
        firewall =
          let
            ports = config.containers."dnsmasq".config.services.dnsmasq.settings.port;
          in
          {
            allowedTCPPorts = ports;
            allowedUDPPorts = ports;
          };
      };
    };
  };
}
