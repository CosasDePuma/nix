{ config, lib, pkgs, inputs, ... }: rec {
  imports = [ inputs.disko.nixosModules.default ];

  system.stateVersion = "25.05";
  networking.hostName = "impermanence";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ]; 
  users.users."root".initialPassword = "nixos";
  services.openssh = { enable = true; openFirewall = true; settings.PermitRootLogin = "yes"; };

  boot.readOnlyNixStore = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  hardware.enableAllHardware = true;
  networking.hostId = builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName);

  disko.devices = {
    disk."main" = {
      device = "/dev/sda";
      type = "disk";
      content.type = "gpt";

      content.partitions."boot" = {
        name = "BOOT";
        size = "1M";
        type = "EF02";
      };

      content.partitions."esp" = {
        name = "ESP";
        size = "500M";
        type = "EF00";
        content.type = "filesystem";
        content.format = "vfat";
        content.mountpoint = "/boot";
        content.extraArgs = [ "-n" "ESP" ];
      };

      content.partitions."root" = {
        name = "NIXOS";
        size = "100%";
        content = {
          type = "zfs";
          pool = "rpool";
        };
      };
    };

    zpool."rpool" = {
      type = "zpool";
      mountpoint = "/";
      options.cachefile = "none";
      rootFsOptions = {
        canmount = "off";
        compression = "zstd";
        "com.sun:auto-snapshot" = "false";
      };

      datasets = {
        "nixos" = {
          type = "zfs_fs";
          options.canmount = "off";
        };
        "nixos/root" = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
          postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^rpool/nixos/root@blank$' || zfs snapshot rpool/nixos/root@blank";
        };
        "nixos/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options.mountpoint = "legacy";
        };
        "nixos/persist" = {
          type = "zfs_fs";
          mountpoint = "/nix/persist";
          options.mountpoint = "legacy";
        };
      };
    };
  };
  fileSystems."/" = {
    device = "rpool/nixos/root";
    fsType = "zfs";
  };
  fileSystems."/nix" = {
    device = "rpool/nixos/nix";
    fsType = "zfs";
    neededForBoot = true;
  };
  fileSystems."/nix/persist" = {
    device = "rpool/nixos/persist";
    fsType = "zfs";
  };
  boot.initrd.systemd = { 
    enable = true;
    services."zfs-rollback" = {
      after       = [ "zfs-import-rpool.service" ];
      wantedBy    = [ "initrd.target" ];
      before      = [ "sysroot.mount" ];
      path        = [ pkgs.zfs ];
      description = "Rollback ZFS root filesystem to blank snapshot";
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = "${pkgs.zfs}/bin/zfs rollback -r rpool/nixos/root@blank";
    };
  };
}