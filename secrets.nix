let
  nixos         = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos";
  vm-wonderland = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOEGfHw6oHN1t1TrpseWgsVniWT4IIwi2AcMxV3cmZT9 @wonderland";
in {
  # arkham
  "systems/x86_64-linux/wonderland/secrets/acme-token.age".publicKeys         = [ nixos vm-wonderland ];
  "systems/x86_64-linux/wonderland/secrets/ddclient-token.age".publicKeys     = [ nixos vm-wonderland ];
  "systems/x86_64-linux/wonderland/secrets/smb-credentials.age".publicKeys    = [ nixos vm-wonderland ];
  "systems/x86_64-linux/wonderland/secrets/vaultwarden-passwd.age".publicKeys = [ nixos vm-wonderland ];
}