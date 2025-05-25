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

      "alice" = {
        isNormalUser = true;                    # Regular user account
        description = "Alice in Wonderland";    # Wonderland reference
        initialPassword = null;                 # No password. Authentication and authorization handled via SSH keys.
        home = "/home/users/alice";             # Home directory for the regular users
        group = "users";                        # Primary group for the regular users
        useDefaultShell = true;                 # Use the default shell (usually bash)
        extraGroups = [ "wheel" "sshuser" ];    # wheel for sudo access, sshuser for SSH access
        openssh.authorizedKeys.keys = [         # SSH public keys for authentication
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos@infra"
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