{ config, pkgs, ... }:
let
  user = config.system.primaryUser;
  app = "/Applications/Claude.app/Contents/MacOS/Claude";
  # 自己更新で終了したアプリは ShipIt が launchd の外で起動し直すため、本体を直接起動するだけでは更新のたびに見張りが外れる。動いていれば待ち、いなければ起動する
  watchdog = pkgs.writeShellScript "claude-desktop-watchdog" ''
    while true; do
      if /usr/bin/pgrep -f '^${app}( |$)' >/dev/null; then
        /bin/sleep 30
        continue
      fi
      echo "$(/bin/date '+%Y-%m-%dT%H:%M:%S%z') Claude が動いていないので起動する"
      "${app}"
      rc=$?
      echo "$(/bin/date '+%Y-%m-%dT%H:%M:%S%z') Claude が終了した (終了コード $rc)"
      # 自己更新では ShipIt が本体を差し替えてから起動し直すので、差し替え中に二重に起動しないよう待つ
      /bin/sleep 30
    done
  '';
in
{
  # Remote Control のコンピューターとして常に Claude アプリから使えるよう、デスクトップアプリを cask で入れる。
  homebrew.casks = [ "claude" ];

  # ログイン時に見張りを起動する。open -a はすぐ終わり launchd が再起動を繰り返すため、見張りの中で本体を直接起動して終了を待つ
  launchd.user.agents.claude-desktop = {
    serviceConfig = {
      ProgramArguments = [ "${watchdog}" ];
      RunAtLoad = true;
      # 見張り自体が落ちたときだけ launchd が起こし直す
      KeepAlive = true;
      # 起動直後に落ち続けたときに再起動が詰まらないよう間隔を空ける
      ThrottleInterval = 30;
      # GUI アプリなので Aqua セッション (ログイン済みの画面) でだけ動かす
      LimitLoadToSessionType = "Aqua";
      ProcessType = "Interactive";
      StandardOutPath = "/Users/${user}/Library/Logs/claude-desktop.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/claude-desktop.log";
    };
  };
}
