# クラウドのセッションにはバイパスのモードがないため、Conductor を m1 のローカルで常駐させる (設計正典 R-37、FIX-32)。
# m1 (server) 専用で、sops のトークンと中継名を持つ quartetto-relay.nix が前提。
{
  config,
  pkgs,
  quartettoQtRelay,
  ...
}:
let
  username = config.system.primaryUser;
  homeDir = config.users.users.${username}.home;
  relay = config.quartetto.relay;
  # Conductor の作業フォルダ。CM-04 で quartetto のセッションだけ mod が有効になる
  repoDir = "${homeDir}/Documents/GitHub/quartetto";
  # Hub への認証は中継エージェントと同じ自ホストのトークンを使い、新しい秘密を増やさない (FIX-32 (2))
  tokenPath = config.sops.secrets."quartetto_relay_token_${relay.host}".path;
  logPath = "${homeDir}/Library/Logs/quartetto-conductor.log";

  # 信頼ダイアログが書く値そのもの。無いと remote-control のセッションが信頼の確認で止まる
  trustDefaults = builtins.toJSON {
    allowedTools = [ ];
    mcpContextUris = [ ];
    mcpServers = { };
    enabledMcpjsonServers = [ ];
    disabledMcpjsonServers = [ ];
    hasClaudeMdExternalIncludesApproved = false;
    hasClaudeMdExternalIncludesWarningShown = false;
  };

  # ~/Documents に触るのは macOS の /bin/bash にする。書類フォルダの保護は実行ファイルごとに許可を見るため、
  # 同じ形 (/bin/bash で cd してから claude を exec) で動いている claude-local の LaunchAgent に合わせる
  startScript = pkgs.writeText "quartetto-conductor-start.sh" ''
    log() { echo "$(/bin/date '+%Y-%m-%dT%H:%M:%S%z') $*"; }

    # 再起動の直後は sops-nix がまだトークンを置いていないことがあるため、最大 10 分待つ (FIX-28 と同じ)
    i=0
    while [ ! -s ${tokenPath} ] && [ "$i" -lt 600 ]; do
      /bin/sleep 1
      i=$((i+1))
    done
    if [ ! -s ${tokenPath} ]; then
      log "Hub のトークン (${tokenPath}) が 10 分待っても置かれませんでした"
      exit 1
    fi

    # quartetto のクローンは人間が置く。無い間は KeepAlive の再起動でログを埋めないよう間を置いて終わる
    if [ ! -d ${repoDir}/.git ]; then
      log "${repoDir} に quartetto のクローンがありません"
      /bin/sleep 300
      exit 1
    fi
    cd ${repoDir} || exit 1

    # ~/.claude.json は動いている他の claude も書き換えるため、信頼済みなら触らず、書くときは一時ファイルから置き換える
    claude_json=${homeDir}/.claude.json
    [ -f "$claude_json" ] || echo '{}' > "$claude_json"
    if ! ${pkgs.jq}/bin/jq -e --arg p ${repoDir} '.projects[$p].hasTrustDialogAccepted == true' "$claude_json" >/dev/null; then
      tmp="$claude_json.quartetto-conductor.$$"
      if ${pkgs.jq}/bin/jq --arg p ${repoDir} --argjson d '${trustDefaults}' \
        '.projects[$p] = ((.projects[$p] // $d) + {hasTrustDialogAccepted: true})' \
        "$claude_json" > "$tmp"; then
        /bin/chmod 600 "$tmp"
        /bin/mv "$tmp" "$claude_json"
        log "${repoDir} を信頼済みにしました"
      else
        /bin/rm -f "$tmp"
        log "~/.claude.json を読めず、信頼を書けませんでした"
        exit 1
      fi
    fi

    log "Conductor を起動します"
    exec /opt/homebrew/bin/claude remote-control --permission-mode bypassPermissions --name Conductor
  '';
in
{
  launchd.user.agents.quartetto-conductor = {
    serviceConfig = {
      # 起動前にトークンとクローンを待ち、フォルダの信頼を書いてから claude に置き換わる
      ProgramArguments = [
        "/bin/bash"
        "${startScript}"
      ];
      # ログイン時に Conductor を立ち上げる
      RunAtLoad = true;
      # Conductor は人間の唯一の窓口なので、落ちたら launchd が起こし直す
      KeepAlive = true;
      # 起動直後に落ち続けたときに再起動が詰まらないよう間隔を空ける
      ThrottleInterval = 30;
      # claude CLI の認証は GUI セッションのキーチェーンにあるため、ログイン済みの画面でだけ動かす (V-06)
      LimitLoadToSessionType = "Aqua";
      # 人間と対話する常駐なので、バックグラウンド扱いの資源制限をかけさせない
      ProcessType = "Interactive";
      EnvironmentVariables = {
        # 信頼の書き込みと claude の設定の読み先を、launchd の環境に頼らず固定する
        HOME = homeDir;
        # launchd の既定の PATH は /usr/bin:/bin だけのため、Conductor が呼ぶものを明示する
        PATH = builtins.concatStringsSep ":" [
          # m5 への ssh の ProxyCommand (RL-07)
          "${quartettoQtRelay}/bin"
          # G-11 の pnpm verify を Node.js 24 (LG-04) で動かす
          "${pkgs.nodejs_24}/bin"
          # claude-local の qt-gui-run (FIX-27)
          "${homeDir}/.local/bin"
          # gh (GitHub の MCP の代わり。R-37) は利用ユーザーのプロファイルにある
          "/etc/profiles/per-user/${username}/bin"
          "/run/current-system/sw/bin"
          "/nix/var/nix/profiles/default/bin"
          # git と pnpm は Homebrew にある
          "/opt/homebrew/bin"
          "/opt/homebrew/sbin"
          "/usr/local/bin"
          "/usr/bin"
          "/bin"
          "/usr/sbin"
          "/sbin"
        ];
        # mod と qt-relay の Hub の接続先。中継エージェントと同じ Hub を指す
        QT_HUB_URL = relay.hubUrl;
        # ローカルにはプロキシのトークン注入がないため、mod と qt-relay がこのファイルのトークンを付ける (FIX-32 (3))
        QT_HUB_TOKEN_FILE = tokenPath;
        # hostname (m1server) は executor の ssh_host (m1) と違うため、自ホストの判定に中継名を渡す (FIX-32 (5))
        QT_RELAY_HOST = relay.host;
      };
      # 起動の失敗と remote-control のセッション URL をここで追えるようにする
      StandardOutPath = logPath;
      StandardErrorPath = logPath;
    };
  };
}
