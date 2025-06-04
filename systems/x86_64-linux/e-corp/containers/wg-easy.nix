{ domain, safeDir, ... }: { config, ... }: {
  virtualisation.oci-containers.containers."wg-easy" = {
    autoStart = true;                             # Automatically start the container
    image = "ghcr.io/wg-easy/wg-easy:nightly";    # Image to use # FIXME(safety): Use a 'latest' or 'production'
    hostname = "wg-easy";                         # Container hostname
    capabilities = {                              # Capabilities to add to the container
      NET_ADMIN = true;
      NET_RAW = true;
      SYS_MODULE = true;
    };
    environment = {
      ENABLE_PROMETHEUS_METRICS = "true";         # Enable prometheus metrics
      LANG = "en";                                # Language of the UI
      WG_HOST = "vpn.${domain}";                  # Domain where the service is accessible
      WG_DEFAULT_ADDRESS = "10.0.0.x";            # Default address for wireguard clients
      UI_ENABLE_SORT_CLIENTS = "true";            # Enable sorting clients
      UI_TRAFFIC_STATS = "true";                  # Enable traffic stats
      UI_CHART_TYPE = "2";                        # Chart type (0: disable, 1: line, 2: area, 3: bars)
      WG_ALLOWED_IPS = "10.0.0.0/8,192.168.1.0/24";
      WG_DEFAULT_DNS = config.containers."dnsmasq".localAddress;
    };
    extraOptions = [                              # Extra options for the container
      "--sysctl=net.ipv4.ip_forward=1"            # Enable IPv4 forwarding
      "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
    ];
    labels = {                                    # Labels for the container
      "traefik.enable" = "true";                  # Enable Traefik
      "traefik.http.routers.wg-easy.rule" = "Host(`vpn.${domain}`)";
      "traefik.http.services.wg-easy.loadbalancer.server.port" = "51821";
    };
    ports = [ "0.0.0.0:51820:51820/udp" ];        # Ports to expose
    volumes = [                                   # Volumes to mount
      "${safeDir}/wg-easy:/etc/wireguard:rw"
    ];
  };
}