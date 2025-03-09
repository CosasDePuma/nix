{ pkgs, ... }:
let
  address = "192.168.1.2";
  user = "joker";
  domain = "kike.wtf";
  nfs_server = "192.168.1.252:/mnt/nfs";
in {
  # Networking
  networking.hostName = "arkham";
  networking.interfaces."eth0".ipv4.addresses = [{ inherit address; prefixLength = 24; }];
  networking.defaultGateway.interface = "eth0";
  networking.defaultGateway.address = "192.168.1.1";

  # User
  users.users."${user}" = {
    description = "Why so serious?";
    createHome = false;
    password = null;
    isSystemUser = true;
    group = "users";
    extraGroups = [ "wheel" ];
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos@infra" ];
  };
  services.openssh.settings.AllowUsers = [ "${user}" ];

  # Services: NFS client
  fileSystems."/mnt/nfs" = {
    device = "${nfs_server}";
    mountPoint = "/mnt/nfs";
    fsType = "nfs";
    options = [ "nfsvers=4.2" "defaults" "nolock" "rw" "soft" "sync" "x-systemd.automount" "noauto" ];
  };

  # Services: DNS
  services.dnsmasq.enable = true;
  services.dnsmasq.settings.server = [ "1.1.1.1" "8.8.8.8" ];
  services.dnsmasq.settings.address = [ "/${domain}/${address}" "/*.${domain}/${address}" ];
  services.dnsmasq.settings.bind-interfaces = true;
  services.dnsmasq.settings.interface = "eth0";
  services.dnsmasq.settings.no-resolv = true;
  services.dnsmasq.settings.cache-size = 1000;
  services.dnsmasq.settings.dns-forward-max = 150;

  # Services: Traefik
  services.traefik.enable = true;
  services.traefik.group = "podman";
  services.traefik.dataDir = "/var/lib/traefik";
  services.traefik.environmentFiles = [ "/mnt/nfs/lab/.env" ];
  services.traefik.staticConfigOptions = {
    accesslog.format = "common";
    accesslog.filepath = "/var/lib/traefik/access.log";
    api.dashboard = true;
    api.insecure = true;
    certificatesResolvers.letsencrypt.acme.email = "acme@${domain}";
    certificatesResolvers.letsencrypt.acme.storage = "/var/lib/traefik/acme.json";
    certificatesResolvers.letsencrypt.acme.caServer = "https://acme-v02.api.letsencrypt.org/directory";
    certificatesResolvers.letsencrypt.acme.certificatesDuration = 8760;
    certificatesResolvers.letsencrypt.acme.preferredChain = "ISRG Root X1";
    certificatesResolvers.letsencrypt.acme.keyType = "RSA4096";
    certificatesResolvers.letsencrypt.acme.dnsChallenge.delayBeforeCheck = 0;
    certificatesResolvers.letsencrypt.acme.dnsChallenge.provider = "cloudflare";
    certificatesResolvers.letsencrypt.acme.dnsChallenge.resolvers = [ "1.1.1.1" "8.8.8.8" ];
    entrypoints.http.address = ":80/tcp";
    entrypoints.http.asDefault = true;
    entrypoints.http.http.redirections.entrypoint.to = "https";
    entrypoints.http.http.redirections.entrypoint.scheme = "https";
    entrypoints.https.address = ":443/tcp";
    entrypoints.https.http.tls.certResolver = "letsencrypt";
    entrypoints.https.http.tls.domains = [ { main = "${domain}"; sans = [ "*.${domain}" ]; } ];
    entrypoints.wireguard.address = ":51820/udp";
    global.checkNewVersion = true;
    global.sendAnonymousUsage = false;
    log.level = "DEBUG";
    providers.docker.endpoint = "unix:///var/run/podman/podman.sock";
    providers.docker.exposedByDefault = false;
    providers.docker.watch = true;
  };
  services.traefik.dynamicConfigOptions = {
    http.middlewares.all.chain.middlewares = [ "compress@file" "jokes@file" ];
    http.middlewares.compression.compress.minResponseBodyBytes = 1024;
    http.middlewares.compression.compress.excludedContentTypes = [ "text/event-stream" ];
    http.middlewares.https-only.chain.middlewares = [ "https-redirect@file" "hsts@file" ];
    http.middlewares.https-redirect.redirectScheme.permanent = true;
    http.middlewares.https-redirect.redirectScheme.port = "443";
    http.middlewares.https-redirect.redirectScheme.scheme = "https";
    http.middlewares.hsts.headers.forceSTSHeader = true;
    http.middlewares.hsts.headers.stsPreload = true;
    http.middlewares.hsts.headers.stsSeconds = 31536000;
    http.middlewares.hsts.headers.stsIncludeSubdomains = true;
    http.middlewares.jokes.headers.customResponseHeaders.Server = "'; DROP TABLE users; -- /*";
    http.middlewares.jokes.headers.customResponseHeaders.X-PoweredBy = "Pumas, unicorns and rainbows";
    http.middlewares.jokes.headers.customResponseHeaders.X-NaNaNaNaNaNaNaNa = "Batman!";
    http.middlewares.jokes.headers.customResponseHeaders.X-Clacks-Overhead = "GNU K.F.";
  };

  # Services: Podman
  virtualisation.oci-containers.backend = "podman";
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
  virtualisation.podman.autoPrune.enable = true;
  virtualisation.podman.autoPrune.dates = "daily";
  virtualisation.podman.autoPrune.flags = [ "--all" "--force" "--volumes" ];

  # Containers: WG-Easy
  virtualisation.oci-containers.containers."wg-easy" = {
    image = "ghcr.io/wg-easy/wg-easy:latest";
    volumes = [ "/mnt/nfs/lab/wg-easy:/etc/wireguard:rw" ];
    environment = {
      WG_HOST = "${domain}";
      WG_DEFAULT_ADDRESS = "10.10.0.x";
      WG_DEFAULT_DNS="${address}";
      WG_ALLOWED_IPS = "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";
      WG_LANG = "en";
      UI_CHART_TYPE = "2";
      UI_TRAFFIC_STATS = "true";
      UI_ENABLE_SORT_CLIENTS = "true";
    };
    extraOptions = [
      "--privileged"
      "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
      "--sysctl=net.ipv4.ip_forward=1"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.wg-easy.rule" = "Host(`vpn.${domain}`)";
      "traefik.http.routers.wg-easy.entrypoints" = "http,https";
      "traefik.http.routers.wg-easy.service" = "wg-easy";
      "traefik.http.services.wg-easy.loadbalancer.server.port" = "51821";
      "traefik.udp.routers.wireguard.entrypoints" = "wireguard";
      "traefik.udp.routers.wireguard.service" = "wireguard";
      "traefik.udp.services.wireguard.loadbalancer.server.port" = "51820";
    };
  };
}