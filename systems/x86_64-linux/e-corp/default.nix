{ lib, namespace, ... }: let
  domain = "kike.wtf";
  ipv4 = "192.168.1.2";
in {
  "${namespace}" = {
    # Hardware
    hardware.disk = "/dev/sda";
    hardware.isVM = true;

    # i18n
    i18n.timezone = "Europe/Madrid";

    # Networking
    networking.ipv4 = ipv4;
    networking.hostName = "e-corp";
    networking.firewall.enable = false;

    # System
    nixos.followFlake = "github:cosasdepuma/nix";

    # Users
    users.administrator.username = "elliot";
    users.administrator.description = "Hello, friend.";
    users.administrator.sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos@infra";

    # --- Server

    # DNSmasq
        # WG-Easy
    oci-containers.dnsmasq.enable = true;
    oci-containers.dnsmasq.records = { "${domain}" = ipv4; };

    # WG-Easy
    oci-containers.wg-easy.enable = true;
    oci-containers.wg-easy.dns = [ ipv4 ];
    oci-containers.wg-easy.publicHost = "vpn.${domain}";

    # ---- Services

    # Jails
    services.fail2ban.enable = true;

    # Shared folders
    services.nfs.client.server = "192.168.1.252:/mnt/nfs";
    services.nfs.client.mountpoint = "/mnt/nfs";

    # OCI Containers
    services.docker.enable = true;

    # SSH
    services.sshd.enable = true;
    services.sshd.port = 10022;
  };
}