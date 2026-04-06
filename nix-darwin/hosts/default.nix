# 全ホストの定義。差分（ホスト名・ユーザー名・追加モジュール）のみを記述する。
{ configName }:
let
  hosts = {
    game      = { hostName = "Macintosh";  username = "shuya";       extraModules = [ ../modules/dock-game-dev.nix ]; };
    work      = { hostName = "PCmac24055"; username = "shuya.izumi"; extraModules = []; };
    server    = { hostName = "m1server";   username = "shuya";       extraModules = [ ../modules/power-server.nix ]; };
  };
  cfg = hosts.${configName};
in
{ ... }: {
  imports = [
    ../modules/base.nix
    ../modules/homebrew.nix
  ] ++ cfg.extraModules;

  networking.hostName = cfg.hostName;
  system.primaryUser = cfg.username;
  users.users.${cfg.username} = {
    name = cfg.username;
    home = "/Users/${cfg.username}";
  };
}
