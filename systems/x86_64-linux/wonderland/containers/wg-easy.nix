{
  config ? "not imported as a module",
  domain ? "domain not defined",
  safeDir ? "/persist",
  ...
}:
{
  virtualisation.oci-containers.containers."wg-easy" = {
    autoStart = true;
    image = "ghcr.io/wg-easy/wg-easy:nightly"; # Image to use # FIXME(safety): Use a 'latest' or 'production'
    hostname = "wg-easy";
    networks = [ "public" ];
    capabilities = {
      NET_ADMIN = true;
      NET_RAW = true;
      SYS_MODULE = true;
    };
    environment = {
      ENABLE_PROMETHEUS_METRICS = "true";
      LANG = "en";
      WG_HOST = "vpn.${domain}";
      WG_DEFAULT_ADDRESS = "10.0.0.x";
      UI_ENABLE_SORT_CLIENTS = "true";
      UI_TRAFFIC_STATS = "true";
      UI_CHART_TYPE = "2";
      WG_ALLOWED_IPS = "10.0.0.0/8,192.168.1.0/24";
      WG_DEFAULT_DNS = config.containers."dnsmasq".localAddress;
    };
    extraOptions = [
      "--sysctl=net.ipv4.ip_forward=1"
      "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.wg-easy.rule" = "Host(`vpn.${domain}`)";
      "traefik.http.services.wg-easy.loadbalancer.server.port" = "51821";
    };
    ports = [ "0.0.0.0:51820:51820/udp" ];
    volumes = [
      "${safeDir}/wg-easy:/etc/wireguard:rw"
    ];
  };
}
