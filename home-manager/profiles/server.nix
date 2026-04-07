{ config, lib, pkgs, ... }:
let
  homeDir = config.home.homeDirectory;
  claudeRemoteLogDir = "${homeDir}/.claude/remote-logs";
in
{
  programs.openclaw = {
    enable = true;
    # OpenClaw が最低限要求する documents 群を repo 管理にする。
    documents = ./server-openclaw-documents;

    # まずはローカル gateway を常駐させる最小構成にして、
    # bot や provider の接続情報は server 側で順次足す。
    config = {
      gateway.mode = "local";
    };

    # 既存の Home Manager / system 側で入れている CLI は重複導入しない。
    excludeTools = [
      "git"
      "jq"
      "ripgrep"
    ];

    instances.default = {
      enable = true;
      # batteries-included package。macOS app と gateway をまとめて扱う。
      package = pkgs.openclaw;
    };
  };

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
        "/bin/bash"
        "${homeDir}/.claude/claude-remote-listener.sh"
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
