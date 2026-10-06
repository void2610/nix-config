{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  claudeRemoteLogDir = "${homeDir}/.claude/remote-logs";
  claudeRemoteListenerDir = "${homeDir}/Documents/GitHub/claude-remote-listener";
  colimaLogDir = "${homeDir}/.colima/logs";
  # ~/Documents は TCC で保護され launchd から読めないため、homelab は srv 配下に置く
  immichBackupDir = "${homeDir}/srv/homelab/immich/backup";
  immichBackupLogDir = "${homeDir}/.local/state/immich-backup";
in
{
  # リモート起動スクリプトの launchd ログ出力先を先に作る。
  home.activation.claudeRemoteLogDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${claudeRemoteLogDir}
  '';

  # ntfy.sh 経由の Claude リモート制御リスナーをユーザー常駐で動かす。
  launchd.agents.claude-remote-listener = {
    enable = true;
    config = {
      Label = "dev.void2610.claude-remote-listener";
      ProgramArguments = [
        "/run/current-system/sw/bin/bash"
        "${claudeRemoteListenerDir}/claude-remote-listener.sh"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      WorkingDirectory = homeDir;
      StandardOutPath = "${claudeRemoteLogDir}/launchd-stdout.log";
      StandardErrorPath = "${claudeRemoteLogDir}/launchd-stderr.log";
      EnvironmentVariables = {
        HOME = homeDir;
        PATH = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/run/current-system/sw/bin";
      };
    };
  };

  home.activation.colimaLogDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${colimaLogDir}
  '';

  # Immich を再起動後も自動復帰させるため、Docker ランタイムの colima を起動時に立ち上げる。
  launchd.agents.colima = {
    enable = true;
    config = {
      Label = "dev.void2610.colima";
      # colima.yaml の値が実 VM とずれても起動が壊れないよう、リソースは引数で明示する。
      ProgramArguments = [
        "${pkgs.colima}/bin/colima"
        "start"
        "--cpu"
        "4"
        "--memory"
        "6"
        "--disk"
        "100"
      ];
      RunAtLoad = true;
      # colima start は VM 起動後に終了するため、KeepAlive を付けると起動を繰り返す。
      KeepAlive = false;
      WorkingDirectory = homeDir;
      StandardOutPath = "${colimaLogDir}/launchd-stdout.log";
      StandardErrorPath = "${colimaLogDir}/launchd-stderr.log";
      EnvironmentVariables = {
        HOME = homeDir;
        # launchd は zsh の PATH を継承せず、colima は limactl 等を PATH から解決する。
        PATH = "${pkgs.colima}/bin:/etc/profiles/per-user/${config.home.username}/bin:/usr/bin:/bin:/usr/sbin:/sbin:/run/current-system/sw/bin";
      };
    };
  };

  home.activation.immichBackupLogDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${immichBackupLogDir}
  '';

  # Immich の写真と DB ダンプを R2 へ退避する。認証情報は backup.env にあり nix では管理しない。
  launchd.agents.immich-backup = {
    enable = true;
    config = {
      Label = "dev.void2610.immich-backup";
      ProgramArguments = [ "${immichBackupDir}/immich-backup.sh" ];
      # Unity ビルドと GitHub Actions のジョブを避けて深夜に回す。
      StartCalendarInterval = [
        {
          Hour = 3;
          Minute = 0;
        }
      ];
      # スリープ等で 3:00 を跨いだ場合に復帰後の実行を促す。
      RunAtLoad = false;
      WorkingDirectory = immichBackupDir;
      StandardOutPath = "${immichBackupLogDir}/stdout.log";
      StandardErrorPath = "${immichBackupLogDir}/stderr.log";
      EnvironmentVariables = {
        HOME = homeDir;
        # restic・docker・gzip を launchd の最小 PATH から解決できるようにする。
        PATH = "/etc/profiles/per-user/${config.home.username}/bin:/usr/bin:/bin:/usr/sbin:/sbin:/run/current-system/sw/bin";
      };
    };
  };
}
