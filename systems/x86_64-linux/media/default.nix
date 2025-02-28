{ namespace, pkgs, ... }: {
  "${namespace}" = {
    # Hardware
    hardware.disk = "/dev/sda";
    hardware.isVM = true;

    # i18n
    i18n.timezone = "Europe/Madrid";

    # Networking
    networking.hostName = "media";
    networking.ipv4 = "192.168.1.3";
    networking.firewall.enable = true;

    # System
    nixos.followFlake = "github:cosasdepuma/nix";

    # Users
    users.administrator.username = "elliot";
    users.administrator.description = "Hello, friend.";
    users.administrator.sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos@infra";

    # ---- Services

    # Fail2Ban
    services.fail2ban.enable = true;

    # NFS Client
    services.nfs.client.server = "192.168.1.252:/mnt/nfs";
    services.nfs.client.mountpoint = "/mnt/nfs";

    # Podman
    services.podman.enable = true;

    # SSHd
    services.sshd.enable = true;
    services.sshd.port = 10022;
  };


  # Jellyfin
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  environment.systemPackages = [
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
  ];
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      # OpenCL support for intel CPUs before 12th gen
      # see: https://github.com/NixOS/nixpkgs/issues/356535
      intel-compute-runtime-legacy1 
      vpl-gpu-rt # QSV on 11th gen or newer
      intel-media-sdk # QSV up to 11th gen
    ];
  };
}