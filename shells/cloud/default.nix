{ pkgs, ... }: with pkgs; mkShell {
  NIX_CONFIG = "experimental-features = nix-command flakes";
  buildInputs = [
    awscli2
    azure-cli
    azurehound
    pacu
    prowler
  ];
  shellHook = ''
    help() {
      echo 
      echo "+--------------------+"
      echo "| Available commands |"
      echo "+--------------------+"
      echo
      echo "aws                |> AWS CLI"
      echo "az                 |> Azure CLI"
      echo "azurehound         |> Azure Active Directory enumeration"
      echo "pacu               |> AWS pentesting framework"
      echo "prowler            |> Configuration security assessment"
      echo
    }
    clear && help
  '';
}
