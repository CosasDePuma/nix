{ config, options, lib, namespace, ... }: {
  options.${namespace}.users = {
    group = lib.mkOption {
      type = lib.types.singleLineStr;
      default = "users";
      description = "The default group name for users.";
    };
  };

  config.users = {
    groups."${config.${namespace}.users.group}" = lib.mkDefault {};
  };
}