{
  imports = [
    ../modules/base.nix
    ../modules/homebrew.nix
  ];

  networking.hostName = "work-dev";

  system.primaryUser = "shuya";

  users.users.shuya = {
    name = "shuya";
    home = "/Users/shuya";
  };
}
