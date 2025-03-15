{ config, options, lib, namespace, ... }: {
  options."${namespace}".users.administrator = {
    username = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "root";
      description = "The administrator username.";
    };

    description = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "";
      description = "The administrator description.";
    };

    password = lib.mkOption {
      type = lib.types.nullOr lib.types.singleLineStr;
      default = null;
      description = "The administrator password.";
    };

    sshPubKey = lib.mkOption {
      type = lib.types.nullOr lib.types.singleLineStr;
      default = null;
      description = "The administrator SSH public key.";
    };
  };

  config = let
    username = config."${namespace}".users.administrator.username;
    group = config."${namespace}".users.group;
    password = config."${namespace}".users.administrator.password;
    sshPubKey = config."${namespace}".users.administrator.sshPubKey;
  in {
    users.users."${username}" = {
      isSystemUser = lib.mkDefault true;
      createHome = lib.mkDefault true;
      password = lib.mkDefault (if password != null then password else null);
      home = lib.mkDefault (if username == "root" then "/root" else "/home/${group}/${username}");
      description = lib.mkDefault config."${namespace}".users.administrator.description;
      group = lib.mkDefault (if username == "root" then "root" else group);
      useDefaultShell = lib.mkDefault true;
      openssh.authorizedKeys.keys = lib.mkDefault (lib.lists.optional (config.services.openssh.enable && sshPubKey != null) sshPubKey);
      extraGroups = lib.mkDefault (builtins.concatLists [
        (lib.lists.optional (username != "root") "wheel")
        (lib.lists.optional (config.virtualisation.docker.enable) "docker")
        (lib.lists.optional (config.virtualisation.podman.enable) "podman")
        (lib.lists.optional (config.networking.networkmanager.enable) "networkmanager")
      ]);
    };
    users.users."root".password = lib.mkDefault (if username == "root" then password else null);
    services.openssh.settings.AllowUsers = lib.mkDefault (lib.lists.optional (config.services.openssh.enable && sshPubKey!= null) username);
  };
}