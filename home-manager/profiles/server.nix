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
}
