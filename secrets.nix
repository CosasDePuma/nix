let
  nixos     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP9RzisL6wVQK3scDyEPEpFgrcdFYkW9LssnWlORGXof nixos";
  vm-arkham = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA5xJUyNGWhbYwPsv+bh7c3huLESh929iIUdncSPxHY9 @arkham";
in {
  # arkham
  "systems/x86_64-linux/arkham/secrets/acme-token.age".publicKeys         = [ nixos vm-arkham ];
  "systems/x86_64-linux/arkham/secrets/duckdns-token.age".publicKeys      = [ nixos vm-arkham ];
  "systems/x86_64-linux/arkham/secrets/smb-credentials.age".publicKeys    = [ nixos vm-arkham ];
  "systems/x86_64-linux/arkham/secrets/vaultwarden-passwd.age".publicKeys = [ nixos vm-arkham ];
}