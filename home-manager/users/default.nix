{ homeDirectory, username, config, ... }:
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

  # docker compose プラグインを ~/.docker/cli-plugins/ にシンボリックリンクで配置
  home.file.".docker/cli-plugins/docker-compose".source =
    config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/bin/docker-compose";

  programs.home-manager.enable = true;
}
