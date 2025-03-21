{ config, options, lib, namespace, ... }: {
  options."${namespace}".networking = {
    dns = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.singleLineStr;
      default = [ "1.1.1.1" "8.8.8.8" ];
      description = "The DNS servers to use.";
    };

    hostName = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "nixos";
      description = "The machine hostname.";
    };
  };

  config.networking = let
    hostname = config."${namespace}".networking.hostName;
  in {
    hostName = lib.mkDefault hostname;
    hosts."127.0.0.1" = lib.mkDefault [ "localhost" "local.host" ];
    hosts."127.0.0.2" = lib.mkDefault [ hostname  "${hostname}.home" "${hostname}.host" "${hostname}.lan" ];
    nameservers = lib.mkDefault config."${namespace}".networking.dns;
    search = lib.mkDefault [ "home" "host" "lan" ];
  };
}