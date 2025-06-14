{
  config ? throw "not imported as a module",
  lib ? throw "not imported as a module",
  pkgs ? throw "not imported as a module",
  dnsProvider ? null,
  domain ? throw "domain not defined",
  ipv4 ? throw "ipv4 not defined",
  safeDir ? "/persist",
  stateVersion ? "25.05",
  userdesc ? "Default user",
  username ? throw "user not defined",
  ...
}:
{
  # +-------------------------------------------+
  # |                   Boot                    |
  # +-------------------------------------------+

  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
    enableContainers = true;
    readOnlyNixStore = true;
  };

  # +-------------------------------------------+
  # |                 Hardware                  |
  # +-------------------------------------------+

  hardware.enableAllHardware = true;

  # +-------------------------------------------+
  # |                Networking                 |
  # +-------------------------------------------+

  networking = {
    # --- host
    hostName = "e-corp";
    hostId = builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName);

    # --- interfaces
    usePredictableInterfaceNames = false;
    interfaces."eth0".ipv4.addresses = [
      {
        address = ipv4;
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      interface = builtins.head (builtins.attrNames config.networking.interfaces);
      address =
        let
          octects = lib.strings.splitString "." ipv4;
        in
        lib.concatStringsSep "." ((lib.lists.take 3 octects) ++ [ "1" ]);
    };

    # --- dns
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    # --- NAT
    nat = {
      enable = true;
      enableIPv6 = false;
      internalInterfaces = [ "ve-+" ];
      externalInterface = builtins.head (builtins.attrNames config.networking.interfaces);
    };

    # --- firewall
    firewall = {
      enable = true;
      allowPing = false;
      allowedTCPPorts = builtins.map (addr: addr.port) config.services.openssh.listenAddresses;
    };
  };

  # +-------------------------------------------+
  # |                    Nix                    |
  # +-------------------------------------------+

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
      persistent = true;
    };
    settings.allowed-users = [ "@wheel" ];
  };

  # +-------------------------------------------+
  # |                  Nixpkgs                  |
  # +-------------------------------------------+

  nixpkgs.config.allowUnfree = false;

  # +-------------------------------------------+
  # |                 Security                  |
  # +-------------------------------------------+

  security = {
    acme = {
      acceptTerms = true;
      certs."${domain}" = {
        inherit dnsProvider domain;
        email = "acme@${domain}";
        group = "vmachines";
        extraDomainNames = [ "*.${domain}" ];
        dnsResolver = "1.1.1.1:53";
        dnsPropagationCheck = true;
        environmentFile = "/run/agenix/acme.env";
      };
    };
    pam = {
      sshAgentAuth.enable = true;
      services."sudo".sshAgentAuth = true;
    };
    sudo-rs = {
      enable = true;
      execWheelOnly = true;
    };
  };

  # +-------------------------------------------+
  # |                 Services                  |
  # +-------------------------------------------+

  services = {

    # +-----------------------------------------+
    #               Services: Cron
    # +-----------------------------------------+

    cron = {
      enable = true;
      systemCronJobs =
        let
          backup = pkgs.writeShellScriptBin "backup" ''
            #!${pkgs.runtimeShell}
            # Backup script for homelab configuration
            dstfolder="/persist/.backups"
            dstfile="''${dstfolder}/audea-ecorp-$(date +%Y-%m-%d).tar"
            /run/current-system/sw/bin/mkdir -p "''${dstfolder}"
            /run/current-system/sw/bin/tar -cf "''${dstfile}" -T /dev/null
            # -----------
            # --- caddy
            /run/current-system/sw/bin/tar -rf "''${dstfile}" -C /persist caddy
            # --- gitea
            /run/current-system/sw/bin/mkdir -p /tmp/gitea
            /run/current-system/sw/bin/tar -xf /persist/gitea/dump/gitea-backup.tar -C /tmp/gitea
            /run/current-system/sw/bin/tar -rf "''${dstfile}" -C /tmp gitea
            /run/current-system/sw/bin/rm -rf /tmp/gitea
            # --- vaultwarden
            /run/current-system/sw/bin/tar -rf "''${dstfile}" -C /persist vaultwarden/attachments/ vaultwarden/db.sqlite3 vaultwarden/db.sqlite3-shm vaultwarden/db.sqlite3-wal
            # --- wg-easy
            /run/current-system/sw/bin/tar -rf "''${dstfile}" -C /persist wg-easy
            # --- wordpress
            /run/current-system/sw/bin/tar -rf "''${dstfile}" -C /persist wordpress
            # -----------
            /run/current-system/sw/bin/gzip -f "''${dstfile}"
          '';
        in
        [
          # --- reboot
          "01 05  *  *  1  root  /run/current-system/sw/bin/reboot"
          # --- backups
          "00  *  *  *  *  root  ${backup}/bin/backup"
        ];
    };

    # +-----------------------------------------+
    #             Services: DDClient
    # +-----------------------------------------+

    ddclient = {
      enable = config ? "age" && config.age ? "ddclient-token";
      domains = [ domain ];
      interval = "1h";
      protocol = dnsProvider;
      passwordFile = "/run/agenix/ddclient-token";
      verbose = true;
      zone = domain;
    };

    # +-----------------------------------------+
    #             Services: Fail2Ban
    # +-----------------------------------------+

    fail2ban = {
      enable = true;
      maxretry = 3;
      bantime = "1h";
      bantime-increment.enable = true;
      bantime-increment.factor = "24";
      banaction = "%(banaction_allports)s";
    };

    # +-----------------------------------------+
    #             Services: OpenSSH
    # +-----------------------------------------+

    openssh = {
      enable = true;
      allowSFTP = true;
      authorizedKeysInHomedir = false;
      listenAddresses = [
        {
          addr = "0.0.0.0";
          port = 64022;
        }
      ];
      ports = [ ];
      startWhenNeeded = true;
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
        AuthorizedPrincipalsFile = "none";
        ChallengeResponseAuthentication = false;
        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
          "aes256-ctr"
          "aes192-ctr"
          "aes128-ctr"
        ];
        ClientAliveInterval = 300;
        GatewayPorts = "no";
        IgnoreRhosts = true;
        KbdInteractiveAuthentication = false;
        KexAlgorithms = [
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
        ];
        LogLevel = "VERBOSE";
        LoginGraceTime = "30";
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
        MaxAuthTries = 3;
        MaxSessions = 5;
        MaxStartups = "10:30:100";
        PasswordAuthentication = false;
        PermitEmptyPasswords = false;
        PermitRootLogin = "no";
        PrintMotd = false;
        StrictModes = true;
        UseDns = false;
        UsePAM = true;
        X11Forwarding = false;

        # Note: We are not using `AllowGroups = [ "sshuser" ];` here because we only want to allow
        # users that have the group defined in the configuration during build-time.
        AllowUsers = lib.attrsets.mapAttrsToList (name: _: name) (
          lib.attrsets.filterAttrs (_: v: builtins.elem "sshuser" v.extraGroups) config.users.users
        );
      };
    };
  };

  # +-------------------------------------------+
  # |                  System                   |
  # +-------------------------------------------+

  system = {
    inherit stateVersion;

    autoUpgrade = {
      enable = true;
      flake = "github:cosasdepuma/nix/audea";
      dates = "daily";
      operation = "switch";
      persistent = true;
    };

    # +-----------------------------------------+
    #             Container networks
    # +-----------------------------------------+

    activationScripts."oci-containers-networks".text =
      let
        inherit (config.virtualisation.oci-containers) backend;
      in
      ''
        #!/bin/sh
        # Create the OCI containers networks
        ${pkgs."${backend}"}/bin/${backend} network inspect public >/dev/null || \
          ${pkgs."${backend}"}/bin/${backend} network create --subnet=10.200.0.0/24 public
      '';
  };

  # +-------------------------------------------+
  # |                  SystemD                  |
  # +-------------------------------------------+

  systemd.tmpfiles.rules = lib.flatten (
      # --- oci-container volumes
      (lib.mapAttrsToList (
        _: container:
        builtins.map (
          volume:
          lib.optional (lib.hasPrefix safeDir volume) "d ${builtins.head (lib.strings.splitString ":" volume)} 0700 998 998 -"
        ) (container.volumes or [ ])
      ) config.virtualisation.oci-containers.containers)
    ++
      # --- systemd-nspawn bind mounts (safeDir)
      (lib.mapAttrsToList (
        _: container:
        lib.mapAttrsToList (
          _: mount: lib.optional (lib.hasPrefix safeDir mount.hostPath) "d ${mount.hostPath} 0700 999 999 -"
        ) (container.bindMounts or { })
      ) config.containers)
  );

  # +-------------------------------------------+
  # |                   Time                    |
  # +-------------------------------------------+

  time.timeZone = "Europe/Madrid";

  # +-------------------------------------------+
  # |                   Users                   |
  # +-------------------------------------------+

  users = {
    mutableUsers = false;

    # +-----------------------------------------+
    #               Users: Groups
    # +-----------------------------------------+

    groups = lib.mkMerge [
      {
        "users" = { };
        "sshuser" = { };
      }
      (lib.mkIf config.virtualisation.podman.enable {
        "podman" = {
          gid = 998;
        };
      })
      (lib.mkIf config.virtualisation.containers.enable {
        "vmachines" = {
          gid = 999;
        };
      })
    ];

    # +-----------------------------------------+
    #                Users: Users
    # +-----------------------------------------+

    users = {

      # --- alice ---

      "${username}" = {
        isNormalUser = true;
        description = userdesc;
        initialPassword = null;
        home = "/home/users/${username}";
        uid = 1000;
        group = "users";
        useDefaultShell = true;
        extraGroups = [
          "wheel"
          "sshuser"
        ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9Dt0O0OJokuV6x1jcejmHvJiGT8ZEubd5/aHGYEyUi nixos@infra"
        ];
      };

      # --- containers user ---

      "vmachines" = {
        uid = 999;
        createHome = false;
        description = "Containers user";
        group = "vmachines";
        home = "/var/empty";
        isSystemUser = true;
        password = null;
        shell = "/run/current-system/sw/bin/nologin";
      };
    };
  };

  # +-------------------------------------------+
  # |              Virtualisation               |
  # +-------------------------------------------+

  virtualisation = {

    # +-----------------------------------------+
    #         Virtualisation: Containers
    # +-----------------------------------------+

    oci-containers.backend = "docker";

    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "daily";
        flags = [
          "--all"
          "--volumes"
          "--force"
        ];
      };
    };

    # +-----------------------------------------+
    #      Virtualisation: Virtual Machines
    # +-----------------------------------------+

    containers.enable = true;
  };
}
