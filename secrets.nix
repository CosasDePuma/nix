let
  nixos         = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos";
  vm-wonderland = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFTVQZlKrpVh/B93Q5z6O1dx9B2PWoIYDH0sVX8I/iCA @wonderland";
in {
  # arkham
  "systems/x86_64-linux/wonderland/secrets/acme-token.age".publicKeys         = [ nixos vm-wonderland ];
  "systems/x86_64-linux/wonderland/secrets/ddclient-token.age".publicKeys     = [ nixos vm-wonderland ];
  "systems/x86_64-linux/wonderland/secrets/smb-credentials.age".publicKeys    = [ nixos vm-wonderland ];
  "systems/x86_64-linux/wonderland/secrets/vaultwarden-passwd.age".publicKeys = [ nixos vm-wonderland ];
}