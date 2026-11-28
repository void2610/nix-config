# 全ホストの定義。差分（ホスト名・ユーザー名・profile・追加モジュール）のみを記述する。
let
  # flake target 名をキーにして、実ホスト名や利用 profile をまとめる。
  hosts = {
    game = {
      hostName = "Macintosh";
      username = "shuya";
      profile = "game";
      extraModules = [
        ../modules/dock-game-dev.nix
        # Unity Hub から起動した Unity Editor が Nix の node 等を見つけられるようにする。
        # GUI アプリは zsh の PATH を継承しないため、launchd レベルで PATH を設定する。
        ../modules/gui-app-path.nix
        # Strix を server と同じ開発用証明書で署名する
        ../modules/apple-development-signing.nix
        # Remote Control のコンピューターとして使うため、Claude デスクトップアプリを常駐させる
        ../modules/claude-desktop.nix
        # Tailscale SSH で外から入れるよう、GUI 版ではなく tailscaled 常駐にする。
        ../modules/tailscale.nix
        # quartetto の SSH 中継エージェント (RL-08)。この Mac の中継名は m5
        ../modules/quartetto-relay.nix
        { quartetto.relay.host = "m5"; }
        # Conductor が nix-config の反映を人間の手なしで行えるよう、darwin-rebuild だけをパスワードなしの sudo で許す (FIX-32)
        ../modules/darwin-rebuild-sudo.nix
      ];
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
        # Tailscale SSH を受けるため、GUI 版ではなく tailscaled 常駐にする。
        ../modules/tailscale.nix
        ../modules/power-server.nix
        ../modules/github-runner-server.nix
        # runner の Unity は WindowServer が必要なので、コンソールがロック / ログインウィンドウにならないよう固定する。
        ../modules/console-session-server.nix
        # CI の Unity が Licensing Client を spawn して runner の stdio を掴む事故を防ぐため、ログイン時に先に常駐させる
        ../modules/unity-licensing-server.nix
        # Strix を手元の Mac と同じ開発用証明書で署名する
        ../modules/apple-development-signing.nix
        # 無料 Apple ID の署名は 7 日で切れるため、Strix を毎晩ビルドして iPhone に入れ直す
        ../modules/strix-nightly-install-server.nix
        # shinkyo の画面を Cloudflare Tunnel で公開する
        ../modules/cloudflared-server.nix
        # Remote Control のコンピューターとして使うため、Claude デスクトップアプリを常駐させる
        ../modules/claude-desktop.nix
        # quartetto の SSH 中継エージェント (RL-08)。この Mac の中継名は m1
        ../modules/quartetto-relay.nix
        { quartetto.relay.host = "m1"; }
        # quartetto の Conductor を m1 のローカルで常駐させる (R-37、FIX-32)。中継モジュールのトークンを使う
        ../modules/quartetto-conductor.nix
        # Conductor が nix-config の反映を人間の手なしで行えるよう、darwin-rebuild だけをパスワードなしの sudo で許す (FIX-32)
        ../modules/darwin-rebuild-sudo.nix
      ];
    };
  };
in
{
  inherit hosts;

  # 各ホスト共通のベース module に、ホスト固有値だけを注入する。
  moduleFor =
    configName:
    let
      cfg = hosts.${configName};
    in
    { ... }:
    {
      imports = [
        ../modules/base.nix
        ../modules/homebrew.nix
      ]
      ++ cfg.extraModules;

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
