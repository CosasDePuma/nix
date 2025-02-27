{ config, options, lib, namespace, ... }: {
  options.${namespace}.services.sshd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the sshd service.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 22;
      description = "The port to listen on.";
    };

    x11Support = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable X11 forwarding.";
    };

    banner = lib.mkOption {
      type = lib.types.str;
      default = ''
        ==============================================================
        |                   AUTHORIZED ACCESS ONLY                   |
        ==============================================================
        |                                                            |
        |  WARNING: All connections are monitored and recorded       |
        |  Disconnect IMMEDIATELY if you are not an authorized user! |
        |                                                            |
        |  * All actions are logged and monitored                    |
        |  * Unauthorized access will be prosecuted                  |
        |                                                            |
        ==============================================================
      '';
      description = "The banner to display when a client connects.";
    };
  };

  config = let
    username = config.${namespace}.users.administrator.username;
    sshPubKey = config.${namespace}.users.administrator.sshPubKey;
  in lib.mkIf config.${namespace}.services.sshd.enable {
    # SSHd
    services.openssh.enable = lib.mkDefault true;
    services.openssh.ports = lib.mkDefault [ config.${namespace}.services.sshd.port ];
    services.openssh.openFirewall = lib.mkDefault true;
    services.openssh.authorizedKeysInHomedir = lib.mkDefault false;
    services.openssh.settings.KbdInteractiveAuthentication = lib.mkDefault (sshPubKey == null);
    services.openssh.settings.PasswordAuthentication = lib.mkDefault (sshPubKey == null);
    services.openssh.settings.PermitRootLogin = lib.mkDefault (if username != "root" then "no" else if sshPubKey == null then "yes" else "without-password");
    services.openssh.settings.X11Forwarding = lib.mkDefault config.${namespace}.services.sshd.x11Support;
    services.openssh.banner = lib.mkDefault config.${namespace}.services.sshd.banner;

    # SSH Agent
    security.pam.sshAgentAuth.enable = lib.mkDefault true;
    security.pam.sshAgentAuth.authorizedKeysFiles = lib.mkDefault [ "/etc/ssh/authorized_keys.d/%u" ];
    security.pam.services.sudo.sshAgentAuth = lib.mkDefault true;
  };
}