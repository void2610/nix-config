{
  config,
  lib,
  pkgs,
  ...
}:
let
  # runner の Unity は WindowServer を要求するため、primaryUser のログイン済みコンソールセッションが常に必要。
  consoleUser = config.system.primaryUser;
  # 2026-09-28 にコンソールがログインウィンドウ化 (kCGSessionLoginDoneKey=false) し、Unity が WindowServer 待ちで runner 4 台が数時間止まった再発防止の最後の保険。
  consoleWatchdog = pkgs.writeShellScript "console-session-watchdog" ''
    set -u
    LOGIN_DONE=$(/usr/sbin/ioreg -n Root -d1 -a 2>/dev/null \
      | /usr/bin/plutil -extract IOConsoleUsers.0.kCGSessionLoginDoneKey raw -o - - 2>/dev/null || echo unknown)
    if [ "$LOGIN_DONE" = "true" ]; then
      exit 0
    fi
    echo "$(/bin/date '+%Y-%m-%dT%H:%M:%S%z') console not logged in (LoginDone=$LOGIN_DONE), switching back to uid $(/usr/bin/id -u)"
    # askForPassword=false と組み合わせないと loginwindow のパスワード要求で止まる
    "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession" -switchToUserID "$(/usr/bin/id -u)"
  '';
in
{
  system.defaults = {
    # base の askForPassword=true を上書き。server はロック画面に入った時点で runner が WindowServer を使えなくなる
    screensaver = {
      askForPassword = lib.mkForce false;
      askForPasswordDelay = lib.mkForce 0;
    };

    CustomSystemPreferences = {
      # Fast User Switching を無効化し「ログインウィンドウ」への切替経路を塞ぐ (その状態では WindowServer が Unity に応答しない)
      "/Library/Preferences/.GlobalPreferences" = {
        MultipleSessionEnabled = false;
      };
    };

    loginwindow = {
      # pmset autorestart での再起動後にログインウィンドウで止まると runner が動けない。FileVault 有効中は無効化されるが、解除時はその入力でログインされる
      autoLoginUser = consoleUser;
    };
  };

  # idleTime は -currentHost 固有の設定で nix-darwin のオプションが無いため defaults で直接書く。AutoLogOutDelay=0 で無操作時のセッション破棄も止める
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    /usr/bin/sudo -u ${consoleUser} /usr/bin/defaults -currentHost write com.apple.screensaver idleTime -int 0
    /usr/bin/defaults write /Library/Preferences/.GlobalPreferences com.apple.autologout.AutoLogOutDelay -int 0
  '';

  # 上の設定で塞げない経路 (手動操作・未知のトリガ) 向けに、GUI セッション内で 1 分ごとにログインウィンドウ化を検知して復帰を試みる
  launchd.user.agents.console-session-watchdog = {
    serviceConfig = {
      ProgramArguments = [ "${consoleWatchdog}" ];
      StartInterval = 60;
      RunAtLoad = true;
      # /var/log は root 所有で user agent からは開けず EX_CONFIG (78) で起動に失敗するため、ユーザー配下に置く
      StandardOutPath = "/Users/${consoleUser}/Library/Logs/console-session-watchdog.log";
      StandardErrorPath = "/Users/${consoleUser}/Library/Logs/console-session-watchdog.log";
    };
  };
}
