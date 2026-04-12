# 全ホストの定義。差分（ホスト名・ユーザー名・profile・追加モジュール）のみを記述する。
let
  # flake target 名をキーにして、実ホスト名や利用 profile をまとめる。
  hosts = {
    game = {
      hostName = "Macintosh";
      username = "shuya";
      profile = "game";
      extraModules = [ ../modules/dock-game-dev.nix ];
    };

    work = {
      hostName = "PCmac24055";
      username = "shuya.izumi";
      profile = "work";
      extraModules = [ ];
    };

    server = {
      hostName = "m1server";
      username = "shuya";
      profile = "server";
      extraModules = [
        # server だけは GUI 版ではなく tailscaled 常駐に切り替える。
        # Tailscale SSH を受けたい要件を work/game に漏らさないため、ホスト限定で読む。
        ../modules/tailscale.nix
        ../modules/power-server.nix
        ../modules/github-runner-server.nix
      ];
    };
  };
in
{
  inherit hosts;

  # 各ホスト共通のベース module に、ホスト固有値だけを注入する。
  moduleFor = configName:
    let
      cfg = hosts.${configName};
    in
    { ... }: {
      imports = [
        ../modules/base.nix
        ../modules/homebrew.nix
      ] ++ cfg.extraModules;

      networking.hostName = cfg.hostName;
      system.primaryUser = cfg.username;

      # primaryUser から Home Manager 側の homeDirectory も導出するため、
      # darwin 側でユーザー情報を明示しておく。
      users.users.${cfg.username} = {
        name = cfg.username;
        home = "/Users/${cfg.username}";
      };
    };
}
