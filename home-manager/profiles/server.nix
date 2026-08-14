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
}
