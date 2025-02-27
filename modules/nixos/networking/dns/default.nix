{ config, options, lib, namespace, ... }: {
  options.${namespace}.networking = {
    dns = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.singleLineStr;
      default = [ "1.1.1.1" "8.8.8.8" ];
      description = "The DNS servers to use.";
    };
  };

  config.networking = {
    nameservers = config.${namespace}.networking.dns;
  };
}