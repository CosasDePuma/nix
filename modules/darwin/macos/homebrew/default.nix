{ config, options, lib, namespace, ... }: {
  options."${namespace}".macos.homebrew = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Homebrew. This does not install Homebrew itself.";
    };

    brews = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.singleLineStr lib.types.attrs);
      default = {};
      description = "Brews to install.";
    };

    casks = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.singleLineStr lib.types.attrs);
      default = {};
      description = "Casks applications to install.";
    };

    storeApps = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "App Store apps to install. This does not uninstall them automatically.";
    };
  };

  config = {
    homebrew.enable = lib.mkDefault config."${namespace}".macos.homebrew.enable;
    homebrew.global.autoUpdate = lib.mkDefault true;
    homebrew.global.brewfile = lib.mkDefault true;
    homebrew.brews = lib.mkDefault config."${namespace}".macos.homebrew.brews;
    homebrew.casks = lib.mkDefault config."${namespace}".macos.homebrew.casks;
    homebrew.masApps = lib.mkDefault config."${namespace}".macos.homebrew.storeApps;
    homebrew.onActivation.autoUpdate = lib.mkDefault true;
    homebrew.onActivation.cleanup = lib.mkDefault "zap";
  };
}