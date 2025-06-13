{
  config ? "not imported as a module",
  domain ? "domain not defined",
  safeDir ? "/persist",
  ...
}:
let
  int-ipv4 = "10.200.0.3";
  subdomain = "vpn.${domain}";
in
{
  virtualisation.oci-containers.containers."wg-easy" = {
    autoStart = true;
    image = "ghcr.io/wg-easy/wg-easy:14";
    hostname = "wg-easy";
    networks = [ "public" ];
    extraOptions = [
      "--ip=${int-ipv4}"
      "--sysctl=net.ipv4.ip_forward=1"
      "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
    ];
    capabilities = {
      NET_ADMIN = true;
      NET_RAW = true;
      SYS_MODULE = true;
    };
    environment = {
      ENABLE_PROMETHEUS_METRICS = "true";
      LANG = "en";
      WG_HOST = subdomain;
      WG_DEFAULT_ADDRESS = "10.0.0.x";
      PORT = "51821";
      UI_ENABLE_SORT_CLIENTS = "true";
      UI_TRAFFIC_STATS = "true";
      UI_CHART_TYPE = "2";
      WG_ALLOWED_IPS = "10.0.0.0/8";
      WG_DEFAULT_DNS = config.containers."dnsmasq".localAddress;
    };
    ports = [ "0.0.0.0:51820:51820/udp" ];
    volumes = [
      "${safeDir}/wg-easy:/etc/wireguard:rw"
    ];
  };
  containers."caddy".config.services.caddy.virtualHosts."${subdomain}".extraConfig = ''
    reverse_proxy http://${int-ipv4}:${
      config.virtualisation.oci-containers.containers."wg-easy".environment.PORT
    }

    tls /var/lib/acme/${domain}/cert.pem /var/lib/acme/${domain}/key.pem {
      protocols tls1.2 tls1.3
    }
  '';
}
