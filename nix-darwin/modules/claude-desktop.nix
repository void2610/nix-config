{ config, ... }:
let
  user = config.system.primaryUser;
in
{
  # Remote Control のコンピューターとして常に Claude アプリから使えるよう、デスクトップアプリを cask で入れる。
  homebrew.casks = [ "claude" ];

  # ログイン時に起動し、落ちたら起こし直す。open -a はすぐ終わり launchd が再起動を繰り返すため、本体を直接起動する
  launchd.user.agents.claude-desktop = {
    serviceConfig = {
      ProgramArguments = [ "/Applications/Claude.app/Contents/MacOS/Claude" ];
      RunAtLoad = true;
      # 自己更新や Cmd+Q は終了コード 0 で終わる。常時 KeepAlive だと更新後に自分で起動し直した本体と launchd の起動がぶつかるので、異常終了だけを拾う
      KeepAlive = {
        SuccessfulExit = false;
        Crashed = true;
      };
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
