{ config, lib, ... }: {
  config.networking = {
    knownNetworkServices = lib.mkDefault [ "Thunderbolt Bridge" "Wi-Fi" ];
  };
}