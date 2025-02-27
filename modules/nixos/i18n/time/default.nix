{ config, options, lib, namespace, ... }: {
  options.${namespace}.i18n = {
    timezone = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "UTC";
      description = "The timezone of the system.";
    };
  };

  config.time = {
    timeZone = lib.mkDefault config.${namespace}.i18n.timezone;
    hardwareClockInLocalTime = lib.mkDefault true;
  };
}