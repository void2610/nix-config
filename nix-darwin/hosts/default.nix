# 全ホストの定義。差分（ホスト名・ユーザー名・追加モジュール）のみを記述する。
{ configName }:
let
  hosts = {
    Macintosh   = { hostName = "Macintosh";   username = "shuya";       extraModules = []; };
    game-dev    = { hostName = "game-dev";    username = "shuya";       extraModules = []; };
    work-dev    = { hostName = "PCmac24055";  username = "shuya.izumi"; extraModules = [ ../modules/melchior ]; };
    server-node = { hostName = "server-node"; username = "shuya";       extraModules = []; };
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
