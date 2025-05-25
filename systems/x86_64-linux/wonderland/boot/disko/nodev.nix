{ config, lib, inputs, ... }: {
  imports = lib.lists.optional (inputs ? "disko") inputs.disko.nixosModules.default;

  config = lib.mkIf (inputs ? "disko") {
    disko.devices.nodev = {
      # --- tmpfs for /tmp ---
      "/tmp" = {
        fsType = "tmpfs";
        mountOptions = [ "noexec" "size=200M" ];
      };
    };
  };
}