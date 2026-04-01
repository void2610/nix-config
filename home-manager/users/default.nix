{ homeDirectory, username, ... }:
{
  imports = [
    ../modules/packages.nix
    ../modules/git.nix
    ../modules/shell.nix
    ../modules/tmux.nix
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
