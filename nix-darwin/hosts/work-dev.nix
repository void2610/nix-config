{
  imports = [
    ../modules/base.nix
    ../modules/homebrew.nix
    ../modules/melchior
  ];

  networking.hostName = "PCmac24055";

  system.primaryUser = "shuya.izumi";

  users.users."shuya.izumi" = {
    name = "shuya.izumi";
    home = "/Users/shuya.izumi";
  };
}
