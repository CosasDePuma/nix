{ config, options, lib, namespace, ... }: {
  options.${namespace}.services.nfs.client = {
    server = lib.mkOption {
      type = lib.types.nullOr lib.types.singleLineStr;
      default = null;
      description = "NFS server share to be mounted.";
    };

    mountpoint = lib.mkOption {
      type = lib.types.path;
      default = "/mnt";
      description = "NFS share mountpoint.";
    };
  };

  config.fileSystems = let
    server = config.${namespace}.services.nfs.client.server;
    mountpoint = config.${namespace}.services.nfs.client.mountpoint;
  in lib.mkIf (server != null) {
    "${mountpoint}" = {
      device = "${server}";
      mountPoint = "${mountpoint}";
      fsType = "nfs";
      options = [ "nfsvers=4.2" "defaults" "nolock" "rw" "soft" "sync" "x-systemd.automount" "noauto" ];
    };
  };
}