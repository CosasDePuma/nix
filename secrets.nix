let
  audea     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9Dt0O0OJokuV6x1jcejmHvJiGT8ZEubd5/aHGYEyUi audea";
  vm-e-corp = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFTVQZlKrpVh/B93Q5z6O1dx9B2PWoIYDH0sVX8I/iCA @e-corp";
in {
  # e-corp
  "systems/x86_64-linux/e-corp/secrets/acme-token.age".publicKeys         = [ audea vm-e-corp ];
  "systems/x86_64-linux/e-corp/secrets/ddclient-token.age".publicKeys     = [ audea vm-e-corp ];
  "systems/x86_64-linux/e-corp/secrets/vaultwarden-passwd.age".publicKeys = [ audea vm-e-corp ];
}