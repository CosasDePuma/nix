_: _: {
  security = {

    # =============================== Sudo ===============================

    sudo.enable = false;            # Disable regular sudo
    sudo-rs = {                     # Sudo-rs is a memory-safe implementation of sudo
      enable = true;                # Enable super user privileges
      execWheelOnly = true;         # Only allow 'wheel' group to execute 'sudo'
      wheelNeedsPassword = true;    # Force password authentication
    };
  };
}