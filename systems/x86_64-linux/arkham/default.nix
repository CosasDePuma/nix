{ config, pkgs, namespace, ... }:
let
  address = "192.168.1.2";
  user = "joker";
  domain = "kike.wtf";
  flake = "github:cosasdepuma/nix";
in {
  # +-----------------------------------------------------------------------------+
  # |                                  Hardware                                   |
  # +-----------------------------------------------------------------------------+

  # Hardware-specific settings, such as disk selection to ensures that the correct
  # storage device is used for system installation and operation.
  # - Use `btrfs` with subvolumes as the filesystem.
  # - Use `tmpfs` for ephemeral directories like `/tmp`.
  # - Use 'impernanece' for resilience.
  
  "${namespace}".hardware.disk = "/dev/sda";          # Physical disk for installation

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
    defaultEditor = true;                             # Ensures that EDITOR environment variable points to Neovim
    viAlias = true;                                   # Hardlink `vi` to `nvim`
    vimAlias = true;                                  # Hardlink `vim` to `nvim`
  };                                                  # Shell alias for `nano` to `nvim`
  environment.shellAliases."nano" = "${config.programs.neovim.package}/bin/nvim";

  # +-----------------------------------------------------------------------------+
  # |                              Localization                                   |
  # +-----------------------------------------------------------------------------+

  # Configures the system's time zone to ensure correct local time handling.
  
  time.timeZone = "Europe/Madrid";                    # System timezone

  # +-----------------------------------------------------------------------------+
  # |                                   System                                    |
  # +-----------------------------------------------------------------------------+

  # Sets the system version to ensure compatibility with NixOS upgrades.
  # This value should be updated cautiously to match system migrations.
  # This value is just used during the initial installation. This value:
  # - Does NOT mean that the system is out of date, out of support, or vulnerable.
  # - Does NOT mean that packages installed are outdated.
  # - Does NOT upgrade the system automatically.
  # - Must NOT be updated, unless you really know what you are doing.
  
  system.stateVersion = "25.05";

  # Ensures that the Nix store is read-only to prevent accidental modifications.

  boot.readOnlyNixStore = true;

  # Implements automatic maintenance routines to ensure system stability.
  # - Enables automatic garbage collection to free up disk space.
  # - Configures system auto-upgrades to keep software up to date.

  nix.gc = {
    automatic = true;
    dates = "weekly";                                 # Weekly removes old packages and generations
    options = "--delete-older-than 7d";               # Removes everything older than 7 days
    persistent = true;                                # Ensures that garbage collection is executed
  };
  system.autoUpgrade = {
    inherit flake;
    enable = true;
    dates = "daily";                                  # Daily checks for updates
    operation = "switch";                             # Switches to the new system immediately
    persistent = true;                                # Ensures that auto-upgrades are executed
  };

  # +-----------------------------------------------------------------------------+
  # |                         Secure Shell Service (SSH)                          |
  # +-----------------------------------------------------------------------------+

  # Implements multi-layered security controls for SSH access:
  # - Attack surface reduction through security-through-obscurity.
  # - Socket activation for improved resource utilization.
  # - Strict session controls to mitigate brute-force and credential attacks.
  # - User authentication restrictions, ensuring only authorized users can access.
  # - Authentication via public key with password-based methods disabled.
  # - Modern cryptographic stack.
  # - Sudo authentication via SSH agent for enhanced security.

  services.openssh = {
    enable = true;
    ports = [ 64022 ];                                # Obfuscated port to evade automated scanning bots
    startWhenNeeded = true;                           # Resource-efficient socket activation
    openFirewall = true;                              # Always allow SSH connections
    settings = {
      AllowUsers = [ "${user}" ];                     # Restrict SSH access to an authorized user
      ChallengeResponseAuthentication = false;        # Disable password-based authentication (I)
      LoginGraceTime = 30;                            # Grace period for user authentication (30 seconds)
      MaxAuthTries = 3;                               # Maximum authentication attempts before locking
      MaxSessions = 5;                                # Maximum concurrent SSH sessions preventing exhaustion
      KbdInteractiveAuthentication = false;           # Disable password-based authentication (II)
      PermitEmptyPasswords = false;                   # Disable empty password authentication
      PasswordAuthentication = false;                 # Disable password-based authentication (III)
      PermitRootLogin = "no";                         # Prevent root login via SSH
      IgnoreRhosts = true;                            # Disable Rhosts-based authentication
      MaxStartups = "10:30:60";                       # Graceful anti-flood
      X11Forwarding = false;                          # Disable graphical forwarding
                                                      # Modern cryptographic stack
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

  # Implements automated intrusion prevention with Fail2Ban (SSH by default):
  # - Protects against brute-force attacks by banning malicious IPs.
  # - Resource-efficient banning strategy with incremental punishment.
  # - Progressive banning system to deter persistent attackers.
  # - Configured to secure all services by banning across all ports.
  # TODO: Implement more jails (HTTP, etc.)

  services.fail2ban = {
    enable = true;
    maxretry = 3;                                     # Maximum number of failed attempts
    bantime = "1h";                                   # Minimum ban duration
    bantime-increment.enable = true;                  # Enable incremental ban time
    bantime-increment.factor = "24";                  # Increment factor (1h, 1d, 24d, 1,5y, 37y, ...)
    banaction = "%(banaction_allports)s";             # Ban access to all ports
  };

  # Deploys tarpit service (honeypot) to waste attacker resources and detect scanning activity:
  # - Binds to standard SSH port to intercept automated attacks
  # - Slowloris-style connection stretching for attacker time dilution
  # - Integration with security observability pipeline
  # TODO: Implement Graphana & Prometheus (https://github.com/shizunge/endlessh-go)

  services.endlessh-go = {
    enable = true;
    port = 22;
    openFirewall = true;
  };

  # +-----------------------------------------------------------------------------+
  # |                       Security: Privilege Escalation                        |
  # +-----------------------------------------------------------------------------+

  # Implements secure privilege escalation policies:
  # - Enables role-based access control through sudo.
  # - Enhances security by allowing authentication via SSH agent.
  # - Reduces reliance on password-based authorization for privileged operations.

  security.sudo.enable = true;                        # Enables sudo access
  security.pam.sshAgentAuth.enable = true;            # Enables SSH agent authentication
  security.pam.services."sudo".sshAgentAuth = true;   # Enables SSH agent authentication for "sudo"










  # TODO: Document this

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
  # |                            Containerization                                 |
  # +-----------------------------------------------------------------------------+
  
  virtualisation.oci-containers.backend = "podman";
  virtualisation."${config.virtualisation.oci-containers.backend}".enable = true;

  # +-----------------------------------------------------------------------------+
  # |                          Network Applications                               |
  # +-----------------------------------------------------------------------------+
  
  #services.dnsmasq.enable = true;
  #services.traefik.enable = true;
}