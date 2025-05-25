_: {
  users.users."alice" = {
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
}