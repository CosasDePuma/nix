{ config, options, lib, pkgs, namespace, ... }: {
  options."${namespace}".oci-containers.dnsmasq = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable dnsmasq OCI container.";
    };

    records = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Domain-IP pairs for wildcard DNS.";
    };
  };

  config = {
    assertions = [{
      assertion = config.virtualisation."${config.virtualisation.oci-containers.backend}".enable;
      msg = "Virtualisation backend '${config.virtualisation.oci-containers.backend}' is not enabled.";
    }];

    virtualisation.oci-containers.containers = lib.mkIf config."${namespace}".oci-containers.dnsmasq.enable {
      "dnsmasq" = let
        configFile = pkgs.writeText "oci-containers.dnsmasq.conf" (builtins.concatStringsSep "\n" ([
          ''
            conf-dir=/etc/dnsmasq.d/,*.conf
            cache-size=1000
            log-queries
            interface=eth0
            server=1.1.1.1
            server=8.8.8.8
            user=dnsmasq
            group=dnsmasq
            conf-file=/usr/share/dnsmasq/trust-anchors.conf
            dnssec
            no-resolv
            no-hosts
            no-ident
            address=/localhost/127.0.0.1'']
            ++ (lib.attrsets.mapAttrsToList (domain: ip: "address=/${domain}/${ip}") config."${namespace}".oci-containers.dnsmasq.records)));
      in {
        hostname = lib.mkDefault "dnsmasq.host";
        image = lib.mkDefault "dockurr/dnsmasq:latest";
        autoStart = lib.mkDefault true;
        volumes = [ "${configFile}:/etc/dnsmasq.conf:ro" ];
        ports = [ "53:53/tcp" "53:53/udp" ];
      };
    };
  };
}