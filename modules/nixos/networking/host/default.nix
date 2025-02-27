{ config, options, lib, namespace, ... }: {
  options.${namespace}.networking = {
    hostName = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "nixos";
      description = "The machine hostname.";
    };
  };

  config.networking = let
    hostname = config.${namespace}.networking.hostName;
  in {
    hostName = lib.mkDefault hostname;
    search = lib.mkDefault [ "localdomain" ];
    hosts."127.0.0.1" = lib.mkDefault [ "localhost" "localhost.localdomain" ];
    hosts."127.0.0.2" = lib.mkDefault [ hostname  "${hostname}.localdomain" ];
  };
}