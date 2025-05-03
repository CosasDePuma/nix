# +------------------------------------------------------------------------------+
# |                                    README                                    |
# +------------------------------------------------------------------------------+
# | Before installation, a secondary disk under /dev/sdb is required.            |
# | After installation, the command `sudo smbpasswd -a fallout` must be executed |
# +------------------------------------------------------------------------------+

{ config, lib, pkgs, namespace, ... }:
let
  user      = "boy";     smbuser = "fallout";   
  ipv4      = "192.168.1.3"; gw4 = "192.168.1.1";
  sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos";
in rec {
  # +----------------------------------------------------------------------------+
  # |                                  Hardware                                  |
  # +----------------------------------------------------------------------------+

  "${namespace}".disko.disk = "/dev/sda";             # Hardware disk used by disko to create the partitions (module!)

  # +----------------------------------------------------------------------------+
  # |                            Internationalization                            |
  # +----------------------------------------------------------------------------+

  # ================================ Timezone ===================================

  time.timeZone = "Europe/Madrid";                    # System timezone

  # +----------------------------------------------------------------------------+
  # |                                  Network                                   |
  # +----------------------------------------------------------------------------+

  # ==================================== DNS =====================================

  networking.hostName = "vault33";                     # Hostname (also used by Flake)
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];   # Default DNS resolvers

  # ================================= Firewall ===================================

  networking.firewall.enable = true;                  # Enable firewall

  # ================================= Interfaces =================================

  networking.usePredictableInterfaceNames = false;    # Disable modern interface names
  networking.interfaces."eth0".ipv4.addresses = [     # Default interface name
    { address = ipv4; prefixLength = 24; }            # Static IPv4 address
  ];
  networking.defaultGateway = {                       # Default gateway
    interface = "eth0"; address = gw4;
  };

  # +----------------------------------------------------------------------------+
  # |                              Package Manager                               |
  # +----------------------------------------------------------------------------+

  # ============================= Garbage Collection =============================

  nix.gc = {
    automatic = true;                                 # Enable automatic garbage collection
    dates = "weekly";                                 # Weekly removes old packages and generations
    options = "--delete-older-than 7d";               # Removes everything older than 7 days
    persistent = true;                                # Ensures that garbage collection is executed
  };

  # +----------------------------------------------------------------------------+
  # |                                  Services                                  |
  # +----------------------------------------------------------------------------+

  # ====================== IDS (Intrusion Detection System) ======================

  services.fail2ban = {
    enable = true;                                    # Enable the Fail2Ban service
    maxretry = 3;                                     # Maximum number of failed attempts
    bantime = "1h";                                   # Ban time (1 hour)
    bantime-increment.enable = true;                  # Enable incremental ban time
    bantime-increment.factor = "24";                  # Increment factor (1h, 1d, 24d, 1,5y, 37y, ...)
    banaction = "%(banaction_allports)s";             # Ban access to all ports
  };

  # ============================== Samba (SMB/CIFS) ==============================

  services.samba = {
    enable = true;                                    # Enable Samba file sharing service
    openFirewall = true;                              # Open required ports in firewall
    settings = {
      global = {
        "bind interfaces only" = "Yes";               # Only bind to specified network interfaces
        "disable netbios" = "Yes";                    # Disable legacy NetBIOS protocol
        "guest account" = "nobody";                   # Set guest account to nobody user
        "hosts allow" = "${builtins.concatStringsSep "." (lib.lists.take 3 (lib.strings.splitString "." ipv4))}.";
        "hosts deny" = "0.0.0.0/0";                   # Deny access from all other networks
        "interfaces" = ipv4;                          # Listen on defined interfaces
        "invalid users" = [ "root" ];                 # Invalid users
        "map to guest" = "Bad user";                  # Map invalid users to guest account
        "min protocol" = "SMB3";                      # Use SMB3 protocol
        "netbios name" = "Vault33";                   # NetBIOS name
        "security" = "user";                          # Use user-level security
        "server string" = "NAS";                      # Server description
        "server min protocol" = "SMB3";               # Use SMB3 protocol
        "workgroup" = "WORKGROUP";                    # Windows workgroup name
      };
      "homelab" = {
        "path"           = "/nas/backups/homelab";    # Path to backups share
        "comment"        = "Homelab backups";         # Share comment
        "browseable"     = "Yes";                     # Make share visible in network browsing
        "read only"      = "No";                      # Allow write access
        "guest ok"       = "No";                      # Disable guest access
        "create mask"    = "0600";                    # New files permissions (rw-------)
        "directory mask" = "0700";                    # New directory permissions (rwx------)
        "force user"     = "${smbuser}";              # Force files ownership to nobody user
        "force group"    = "smbusers";                # Force files group to nogroup
      };
      "timemachine" = {
        "path"           = "/nas/backups/apple";      # Path to backups share
        "comment"        = "Time Machine backups";    # Share comment
        "browseable"     = "Yes";                     # Make share visible in network browsing
        "read only"      = "No";                      # Allow write access
        "guest ok"       = "No";                      # Disable guest access
        "create mask"    = "0600";                    # New files permissions (rw-------)
        "directory mask" = "0700";                    # New directory permissions (rwx------)
        "force user"     = "${smbuser}";              # Force files ownership to nobody user
        "force group"    = "smbusers";                # Force files group to nogroup
        # --- Time Machine ---
        "fruit:time machine"          = "Yes";        # Enable Time Machine for this share
        "fruit:time machine max size" = "250G";       # Maximum size of Time Machine backups
        "fruit:delete_empty_adfiles"  = "Yes";        # Delete empty AppleDouble files
        "fruit:metadata"              = "stream";     # Enable metadata stream
        "fruit:model"                 = "MacSamba";   # Enable MacSamba model
        "fruit:nfs_aces"              = "No";         # Disable NFS ACLs
        "fruit:posix_rename"          = "Yes";        # Enable POSIX rename
        "fruit:veto_appledouble"      = "No";         # Disable AppleDouble veto
        "fruit:wipe_intentionally_left_blank_rfork" = "Yes";
        "spotlight"                   = "Yes";        # Enable Spotlight indexing
        "vfs objects"                 = "catia fruit streams_xattr";
      };
      "media" = {
        "path"           = "/nas/media";              # Path to media share
        "comment"        = "Media files";             # Share comment
        "browseable"     = "Yes";                     # Make share visible in network browsing
        "read only"      = "No";                      # Allow write access
        "guest ok"       = "No";                      # Disable guest access
        "create mask"    = "0600";                    # New files permissions (rw-------)
        "directory mask" = "0700";                    # New directory permissions (rwx------)
        "force user"     = "${smbuser}";              # Force files ownership to nobody user
        "force group"    = "smbusers";                # Force files group to nogroup
      };
    };
  };
  services.samba-wsdd = {
    enable = true;                                    # Enable the Samba Web Services Discovery service
    interface = ipv4;                                 # Listen on defined interfaces
    workgroup = "WORKGROUP";                          # Windows workgroup name
    openFirewall = true;                              # Open required ports in firewall
  };

  # ============================= SSH (Secure Shell) =============================

  services.openssh = {
    enable = true;                                    # Enable the OpenSSH service
    ports = [ 64022 ];                                # Obfuscated port to evade automated scanning bots
    openFirewall = true;                              # Always allow SSH connections
    startWhenNeeded = true;                           # Resource-efficient socket activation
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
    settings = {
      AllowUsers = [ "${user}" ];                     # Allow only the specified user to connect
      ChallengeResponseAuthentication = false;        # Disable password-based authentication (I)
      IgnoreRhosts = true;                            # Disable Rhosts-based authentication
      KbdInteractiveAuthentication = false;           # Disable password-based authentication (II)
      LoginGraceTime = 30;                            # Grace period for user authentication (30 seconds)
      MaxAuthTries = 3;                               # Maximum authentication attempts before locking
      MaxSessions = 5;                                # Maximum concurrent SSH sessions preventing exhaustion
      MaxStartups = "10:30:60";                       # Graceful anti-flood
      PermitEmptyPasswords = false;                   # Disable empty password authentication
      PasswordAuthentication = false;                 # Disable password-based authentication (III)
      PermitRootLogin = "no";                         # Prevent root login via SSH
      X11Forwarding = false;                          # Disable graphical forwarding
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com" "aes128-gcm@openssh.com" "aes256-ctr" "aes192-ctr" "aes128-ctr"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com" "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
      KexAlgorithms = [
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512" "diffie-hellman-group18-sha512"
      ];
    };
  };
  security.pam.sshAgentAuth.enable = true;            # Enable SSH agent authentication
  security.pam.services."sudo".sshAgentAuth = true;   # Enable sudo via SSH agent

  # +----------------------------------------------------------------------------+
  # |                                  Security                                  |
  # +----------------------------------------------------------------------------+
  
  # ============================ Privilege Escalation ============================

  security.sudo-rs = {                                # Memory-safe sudo replacement
    enable = true;                                    # Enable super user privileges
    execWheelOnly = true;                             # Only allow 'wheel' group to execute 'sudo'
    wheelNeedsPassword = true;                        # Force password authentication
  };

  # +----------------------------------------------------------------------------+
  # |                                   System                                   |
  # +----------------------------------------------------------------------------+

  # ================================ Auto-Upgrade ================================

  system.autoUpgrade = {
    enable = true;                                    # Enable auto-upgrades
    flake = "github:cosasdepuma/nix";                 # Flake to use for auto-upgrades
    dates = "daily";                                  # Daily checks for updates
    operation = "switch";                             # Switches to the new system immediately
    persistent = true;                                # Ensures that auto-upgrades are executed
  };

  # ================================= Filesystem =================================

    fileSystems."/nas" = {
      device = "/dev/sdb";
      fsType = "btrfs";
      options = [ 
        "defaults"
        "noatime"                                     # Don't update access times (better performance)
        "compress=zstd"                               # Enable ZSTD compression
        "autodefrag"                                  # Enable automatic defragmentation
        "space_cache=v2"                              # Use newer space cache version
        "discard=async"                               # Enable TRIM for SSDs
      ];
    };

  systemd.tmpfiles.rules = [
    "d /nas/backups         1700 ${smbuser} smbusers -"
    "d /nas/backups/apple   1700 ${smbuser} smbusers -"
    "d /nas/backups/homelab 1700 ${smbuser} smbusers -"
    "d /nas/media           1700 ${smbuser} smbusers -"
  ];

  # ================================== Release ===================================

  system.stateVersion = "25.05";

  # +----------------------------------------------------------------------------+
  # |                                   Users                                    |
  # +----------------------------------------------------------------------------+

  # =================================== Groups ===================================

  users.groups."users"    = {};                       # Group to organize regular users
  users.groups."smbusers" = {};                       # Group to organize regular users

  # =================================== Users ====================================

  users.users = {

    # --- Regular users ---

    "${user}" = {
      createHome = true;
      description = "Democracy is on negotiable.";    # Fallout reference
      home = "/home/users/${user}";                   # Create home directory inside 'users' folder
      password = null;                                # Disable password authentication
      isNormalUser = true;                            # Regular user account
      useDefaultShell = true;                         # Use default shell
      extraGroups = [ "wheel" ];                      # Grant superuser privileges
      openssh.authorizedKeys.keys = [ sshPubKey ];    # Authorized SSH keys
    };

    # --- Samba users ---

    "${smbuser}" = {
      createHome = false;                             # Don't create a home directory
      description = "Welcome to Vault 33";            # Fallout reference
      home = "/nas";                                  # Home directory
      group = "smbusers";                             # Group
      password = null;                                # Disable password authentication (`smbpasswd -a fallout` should be used instead!)
      isSystemUser = true;                            # System user
    };
  };
}