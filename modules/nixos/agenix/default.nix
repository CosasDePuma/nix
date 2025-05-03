{ config, lib, inputs, ... }:
  lib.optionalAttrs (builtins.hasAttr "agenix" inputs) {
    imports = [ inputs.agenix.nixosModules.default ];

    config = {
      age.identityPaths = lib.mkDefault (lib.optionals
        ((builtins.length config.services.openssh.hostKeys) != 0)
          (builtins.map (x: x.path) (config.services.openssh.hostKeys)));
    };
  }