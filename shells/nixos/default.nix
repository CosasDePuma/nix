{ pkgs, inputs, system, ... }: with pkgs; mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes";
  buildInputs = [
    nh                                                # yet another nix cli wrapper
    nixos-anywhere                                    # nixos installation over ssh
    nixos-rebuild                                     # nixos configuration rebuild

    inputs.ragenix.packages.${system}.default         # secret management
    inputs.darwin.packages.${system}.default          # darwin configuration rebuild
  ];
  shellHook = ''
    help() {
      echo 
      echo "+--------------------+"
      echo "| Available commands |"
      echo "+--------------------+"
      echo 
      echo "ragenix            |> secret management"
      echo "darwin-rebuild     |> darwin configuration rebuild"
      echo "frost              |> flake documentation generator"
      echo "nh                 |> yet another nix cli wrapper"
      echo "nixos-anywhere     |> nixos installation over ssh"
      echo "nixos-rebuild      |> nixos configuration rebuild"
      echo
    }
    clear && help
  '';
}