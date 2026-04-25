{ config, ... }:
let
  # GUI アプリ (Unity Hub から起動する Unity Editor 等) は zsh の PATH を継承しないため、
  # launchctl setenv で macOS の launchd レベルで PATH を流し込む。
  # この PATH を Nix で管理しないと Unity の uLoopMCP が node を見つけられず動かない。
  primaryUser = config.system.primaryUser;

  # Nix と一般的な system path を結合する。
  # 個別の Nix bin パス順序は zsh で実測した順を踏襲して、ユーザー profile が先に効くようにする。
  # /opt/homebrew は GUI アプリから Homebrew パッケージを呼ぶケースに備えて含める。
  guiAppPath = builtins.concatStringsSep ":" [
    "/etc/profiles/per-user/${primaryUser}/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/Users/${primaryUser}/.nix-profile/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
in
{
  # ログイン時に 1 回だけ launchctl setenv を呼ぶ LaunchAgent を配置する。
  # 個別のアプリ起動スクリプトを各 GUI アプリで用意せずに済むよう、ここで一元化する。
  launchd.user.agents.set-gui-app-path = {
    serviceConfig = {
      Label = "com.user.set-gui-app-path";
      # launchd 起動直後 (ログイン直後) に PATH を確定させたいので RunAtLoad を有効化する。
      # KeepAlive は不要 (一度実行すれば PATH は launchd プロセスが保持する)。
      RunAtLoad = true;
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/launchctl setenv PATH \"${guiAppPath}\""
      ];
    };
  };
}
