{ config, pkgs, namespace, ... }:
let
  address = "192.168.1.2";
  user = "joker";
  domain = "kike.wtf";
in {
  # +-----------------------------------------------------------------------------+
  # |                                  Hardware                                   |
  # +-----------------------------------------------------------------------------+
  # Hardware-specific settings, such as disk selection to ensures that the correct
  # storage device is used for system installation and operation.
  # - Use `btrfs` with subvolumes as the filesystem.
  # - Use `tmpfs` for ephemeral directories like `/tmp`.
  # - Use 'impernanece' for resilience.
  
  "${namespace}".hardware.disk = "/dev/sda";

  # +-----------------------------------------------------------------------------+
  # |                                  Packages                                   |
  # +-----------------------------------------------------------------------------+
  # Defines essential system packages that should be available globally.
  # Only minimal tools are included to maintain a lightweight system.
  
  environment.systemPackages = with pkgs; [ ];

  # Configures Neovim as the default system editor.
  # - Enables Neovim as the primary editor.
  # - Provides compatibility aliases for `vi` and `vim` commands.
  # - Provides shell compatibility with the `nano` command.

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
  environment.shellAliases."nano" = "${config.programs.neovim.package}/bin/nvim";

  # +-----------------------------------------------------------------------------+
  # |                                   System                                    |
  # +-----------------------------------------------------------------------------+
  # Sets the system version to ensure compatibility with NixOS upgrades.
  # This value should be updated cautiously to match system migrations.
  
  system.stateVersion = "25.05";

  # Implements automatic maintenance routines to ensure system stability.
  # - Enables automatic garbage collection to free up disk space.
  # - Configures system auto-upgrades to keep software up to date.

  nix.gc.automatic = true;
  system.autoUpgrade.enable = true;

  # +-----------------------------------------------------------------------------+
  # |                              Localization                                   |
  # +-----------------------------------------------------------------------------+
  # Configures the system's time zone to ensure correct local time handling.
  
  time.timeZone = "Europe/Madrid";

  # +-----------------------------------------------------------------------------+
  # |                                Networking                                   |
  # +-----------------------------------------------------------------------------+
  
  networking = {
    hostName = "arkham";
    interfaces."eth0".ipv4.addresses = [{ inherit address; prefixLength = 24; }];
    defaultGateway = { interface = "eth0"; address = "192.168.1.1"; };
    usePredictableInterfaceNames = false;
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    firewall.enable = true;
  };

  # +-----------------------------------------------------------------------------+
  # |                        Users and Authentication                             |
  # +-----------------------------------------------------------------------------+
  
  users.users."${user}" = {
    createHome = true;
    home = "/home/users/${user}";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos@infra" ];
  };

  # +-----------------------------------------------------------------------------+
  # |                           Network Services                                  |
  # +-----------------------------------------------------------------------------+
  
  services.openssh = {
    enable = true;
    ports = [ 64022 ];
    startWhenNeeded = true;
    openFirewall = true;
    settings = {
      AllowUsers = [ "${user}" ];
      ChallengeResponseAuthentication = false;
      LoginGraceTime = 30;
      MaxAuthTries = 3;
      KbdInteractiveAuthentication = false;
      PermitEmptyPasswords = false;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
      Ciphers = [ "chacha20-poly1305@openssh.com" "aes256-gcm@openssh.com" "aes128-gcm@openssh.com" "aes256-ctr" "aes192-ctr" "aes128-ctr" ];
      Macs = [ "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com" ];
      KexAlgorithms = [ "curve25519-sha256@libssh.org" "diffie-hellman-group16-sha512" "diffie-hellman-group18-sha512" ];
    };
    banner = ''
      ==============================================================
      |                   AUTHORIZED ACCESS ONLY                   |
      ==============================================================
      |                                                            |
      |    WARNING: All connections are monitored and recorded.    |
      |  Disconnect IMMEDIATELY if you are not an authorized user! |
      |                                                            |
      |       *** Unauthorized access will be prosecuted ***       |
      |                                                            |
      ==============================================================
    '';
  };

  # TODO: Implement Graphana & Prometheus (https://github.com/shizunge/endlessh-go)
  services.endlessh-go = {
    enable = true;
    port = 22;
    openFirewall = true;
  };

  # +-----------------------------------------------------------------------------+
  # |                                Security                                     |
  # +-----------------------------------------------------------------------------+
  
  services.fail2ban.enable = true;
  security.pam.sshAgentAuth.enable = true;

  # +-----------------------------------------------------------------------------+
  # |                          Network Applications                               |
  # +-----------------------------------------------------------------------------+
  
  services.dnsmasq.enable = true;
  services.traefik.enable = true;

  # +-----------------------------------------------------------------------------+
  # |                            Containerization                                 |
  # +-----------------------------------------------------------------------------+
  
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
}
