_: { config, lib, ... }: {
  users = {
    # ============================== Groups ==============================

    groups = lib.mkMerge [
      {
        "users"     = {};                       # Default group for regular users
        "sshuser"   = {};                       # Group for SSH users
      }
      (lib.mkIf config.virtualisation.podman.enable {
        "podman"    = { gid = 998; };           # Group for OCI containers
      })
      (lib.mkIf config.virtualisation.containers.enable {
        "vmachines" = { gid = 999; };           # Group for systemd-nspawn containers
      })
    ];

    # ============================== Users ===============================

    mutableUsers = false;                       # Disallow mutable users
    users = {

      # --- alice ---

      "elliot" = {
        isNormalUser = true;                    # Regular user account
        description = "Hello, friend.";         # Mr. Robot's reference
        initialPassword = null;                 # No password. Authentication and authorization handled via SSH keys.
        home = "/home/users/elliot";            # Home directory for the regular users
        group = "users";                        # Primary group for the regular users
        useDefaultShell = true;                 # Use the default shell (usually bash)
        extraGroups = [ "wheel" "sshuser" ];    # wheel for sudo access, sshuser for SSH access
        openssh.authorizedKeys.keys = [         # SSH public keys for authentication
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9Dt0O0OJokuV6x1jcejmHvJiGT8ZEubd5/aHGYEyUi audea"
        ];
      };

      # --- containers user ---

      "vmachines" = {
        uid = 999;                              # Force specific UID to match container users
        createHome = false;                     # Disable home directory creation
        description = "Containers user";        # Description
        group = "vmachines";                    # Container group
        home = "/var/empty";                    # Disable home directory
        isSystemUser = true;                    # System user account
        password = null;                        # Disable password authentication
        shell = "/run/current-system/sw/bin/nologin";
      };
    };
  };
}