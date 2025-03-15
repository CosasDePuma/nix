{ pkgs }: with pkgs; mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes";
  buildInputs = [ nh nixos-anywhere nixos-rebuild ];
  shellHook = "alias darwin-rebuild='nix run nix-darwin#darwin-rebuild --'";
}