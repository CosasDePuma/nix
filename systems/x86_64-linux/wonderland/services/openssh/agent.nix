_: {
  security.pam = {
    sshAgentAuth.enable = true;            # Enable SSH agent authentication
    services."sudo".sshAgentAuth = true;   # Enable sudo via SSH agent
  };
}