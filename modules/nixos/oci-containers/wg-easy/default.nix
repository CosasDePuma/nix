{ config, options, lib, namespace, ... }: {
  options."${namespace}".oci-containers.wg-easy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable wg-easy OCI container.";
    };

    dns = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = if config."${namespace}".networking.ipv4 != null then config."${namespace}".networking.ipv4 else [ "1.1.1.1" "8.8.8.8" ];
      description = "DNS server to forward requests to.";
    };

    publicHost = lib.mkOption {
      type = lib.types.nullOr lib.types.singleLineStr;
      default = null;
      description = "Domain or IP address of the public host.";
    };
  };

  config = {
    assertions = [{
      assertion = config.virtualisation."${config.virtualisation.oci-containers.backend}".enable;
      msg = "Virtualisation backend '${config.virtualisation.oci-containers.backend}' is not enabled.";
    }
    {
      assertion = config."${namespace}".oci-containers.wg-easy.publicHost  != null;
      msg = "A public host must be specified.";
    }];

    virtualisation.oci-containers.containers = lib.mkIf config."${namespace}".oci-containers.wg-easy.enable {
      "wg-easy" = {
        hostname = lib.mkDefault "wg-easy.host";
        image = lib.mkDefault "ghcr.io/wg-easy/wg-easy:latest";
        autoStart = lib.mkDefault true;
        environment = {
          WG_HOST = lib.mkDefault config."${namespace}".oci-containers.wg-easy.publicHost;
          WG_DEVICE = lib.mkDefault "eth0";
          WG_DEFAULT_ADDRESS = lib.mkDefault "10.10.0.x";
          WG_DEFAULT_DNS = lib.mkDefault (lib.concatStringsSep "," config."${namespace}".oci-containers.wg-easy.dns);
          WG_ALLOWED_IPS = lib.mkDefault "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";
          WG_LANG = lib.mkDefault "en";
          UI_CHART_TYPE = lib.mkDefault "2";
          UI_TRAFFIC_STATS = lib.mkDefault "true";
          UI_ENABLE_SORT_CLIENTS = lib.mkDefault "true";
        };
        capabilities.NET_ADMIN = lib.mkDefault true;
        extraOptions = lib.mkDefault [
          "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
          "--sysctl=net.ipv4.ip_forward=1"
        ];
        ports = lib.mkDefault [ "51820:51820/udp" "51821:51821/tcp" ];
      };
    };
  };
}