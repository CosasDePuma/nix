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
    dns = lib.mkDefault config."${namespace}".networking.dns;
    hostName = lib.mkDefault hostname;
    localHostName = lib.mkDefault hostname;
    computerName = lib.mkDefault hostname;
    search = lib.mkDefault [ "home" "host" "lan" ];
  };
}