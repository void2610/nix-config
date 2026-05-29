{ config, ... }:
{
  # work プロファイル限定で noclamshell を常駐させる。
  # ログインユーザー権限で動かす必要があるため、system daemon ではなく user agent として登録する。
  launchd.user.agents.noclamshell = {
    serviceConfig = {
      # Homebrew で `/opt/homebrew/bin/noclamshell` に入るバイナリを直接指す。
      # nix-darwin の homebrew module 経由で pirj/noclamshell tap + noclamshell brew を導入済み。
      ProgramArguments = [ "/opt/homebrew/bin/noclamshell" ];

      # pirj/homebrew-noclamshell の Formula が定義する service do ブロックに合わせ、
      # 5 秒ごとに noclamshell を実行する。バイナリ自体は短命に終わる作りのため interval 駆動が前提。
      StartInterval = 5;

      # ログイン直後から効かせたいので、起動時にも 1 度実行する。
      RunAtLoad = true;

      # interval 駆動なのでプロセス常駐を強制する KeepAlive は要らない。
      # 残してしまうと launchd が即時再起動と StartInterval の二重トリガーで動いてしまうため明示的に無効化する。
      KeepAlive = false;

      # 標準出力・標準エラーは debug 用にユーザー領域へ書き出しておく。
      StandardOutPath = "/tmp/noclamshell.out.log";
      StandardErrorPath = "/tmp/noclamshell.err.log";
    };
  };
}
