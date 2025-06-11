{
  inputs ? throw "inputs not defined",
  ...
}:
let
  specialArgs = {
    user = "pumita";
  };
in
inputs.nix-darwin.lib.darwinSystem {
  inherit specialArgs;
  system = "aarch64-darwin";
  modules = [ ./darwin.nix ];
}
