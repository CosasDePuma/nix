_: { config, lib, ... }: {

  # =============================== Agent ================================
    
  security.pam = {
    sshAgentAuth.enable = true;                     # Enable SSH agent authentication
    services."sudo".sshAgentAuth = true;            # Enable sudo via SSH agent
  };

  # ============================== Firewall ==============================
    
  networking.firewall.allowedTCPPorts = builtins.map (addr: addr.port)
    config.services.openssh.listenAddresses;

  # ============================== Service ===============================

  services.openssh = {
    enable = true;                                  # Enable the OpenSSH server
    allowSFTP = true;                               # Enable SCP & SFTP
    authorizedKeysInHomedir = false;                # Disable authorized keys in home directories
    listenAddresses = [{                            # Listen only on IPv4 and custom port
      addr = "0.0.0.0"; port = 64022; }];
    ports = [];                                     # Disable default port 22
    startWhenNeeded = true;                         # Start the service when a connection is made
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
      AuthorizedPrincipalsFile = "none";            # Disable authorized principals file
      ChallengeResponseAuthentication = false;      # Disable challenge-response authentication
      Ciphers = [ "chacha20-poly1305@openssh.com" "aes256-gcm@openssh.com" "aes128-gcm@openssh.com" "aes256-ctr" "aes192-ctr" "aes128-ctr" ];
      ClientAliveInterval = 300;                    # Set client alive interval to 5 minutes
      GatewayPorts = "no";                          # Disable gateway ports
      IgnoreRhosts = true;                          # Ignore .rhosts files
      KbdInteractiveAuthentication = false;         # Disable keyboard-interactive authentication
      KexAlgorithms = [ "curve25519-sha256@libssh.org" "diffie-hellman-group16-sha512" "diffie-hellman-group18-sha512" ];
      LogLevel = "VERBOSE";                         # Set log level to verbose (fail2ban friendly)
      LoginGraceTime = "30";                        # Set login grace time to 30 seconds
      Macs = [ "hmac-sha2-512-etm@openssh.com" "hmac-sha2-256-etm@openssh.com" "umac-128-etm@openssh.com" ];
      MaxAuthTries = 3;                             # Set maximum authentication attempts to 3
      MaxSessions = 5;                              # Set maximum sessions to 10
      MaxStartups = "10:30:100";                    # Set maximum startups to 10, 30%, 100%
      PasswordAuthentication = false;               # Disable password authentication
      PermitEmptyPasswords = false;                 # Disable empty passwords
      PermitRootLogin = "no";                       # Disable root login
      PrintMotd = false;                            # Disable printing the message of the day
      StrictModes = true;                           # Enable strict modes
      UseDns = false;                               # Disable DNS lookups
      UsePAM = true;                                # Enable PAM (Pluggable Authentication Modules)
      X11Forwarding = false;                        # Disable X11 forwarding
      
      # Note: We are not using `AllowGroups = [ "sshuser" ];` here because we only want to allow 
      # users that have the group defined in the configuration to avoid possible attack vectors.
      AllowUsers = lib.attrsets.mapAttrsToList (name: _: name)
        (lib.attrsets.filterAttrs (_: v: builtins.elem "sshuser" v.extraGroups) config.users.users);
    };
  };
}