# quartetto の SSH 中継 (設計正典 6.13、RL-08) を宣言的に管理するモジュール。
# 手で配置せず、このモジュールで sshd の前提・CA の信頼・エージェントの常駐をそろえる。
# 加えるのは m1 (server) と m5 (game) だけ。他ホストには入れない。
{
  config,
  lib,
  quartettoRelayAgent,
  quartettoQtGuiRun,
  ...
}:
let
  username = config.system.primaryUser;
  homeDir = config.users.users.${username}.home;
  relay = config.quartetto.relay;
  # トークンの sops キーはホストごとに分かれる (common.yaml の quartetto_relay_token_m1 / _m5)
  tokenSecret = "quartetto_relay_token_${relay.host}";
in
{
  options.quartetto.relay = {
    # 中継での自ホスト名。Hub の executor の ssh_host と一致させる必要があるため、
    # ホスト定義 (hosts/default.nix) で明示する
    host = lib.mkOption {
      type = lib.types.enum [
        "m1"
        "m5"
      ];
      description = "中継での自ホスト名 (QT_RELAY_HOST)";
    };
    # エージェントの接続先。デプロイ済み Hub の URL を既定にする
    hubUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://quartetto-hub.void2610.workers.dev";
      description = "Hub の URL (QT_HUB_URL)";
    };
  };

  config = {
    # (0) quartetto の flake input を root でも取得できるようにする (FIX-17)。
    # darwin-rebuild は root で走るため、利用ユーザーの ~/.ssh/config にある
    # github 別名が見えず、git+ssh の取得が失敗する。鍵と接続先をシステム側の
    # ssh_config に書くことで、前準備なしで通るようにする
    environment.etc."ssh/ssh_config.d/050-quartetto-github.conf".text = ''
      # quartetto の取得用。root からも読めるよう、鍵は利用ユーザーの実パスで指す
      Host github.com
        User git
        IdentityFile ${homeDir}/.ssh/id_github_rsa
        IdentitiesOnly yes
        # root の known_hosts は空のため、利用ユーザーのものを共有して検証を通す
        UserKnownHostsFile ${homeDir}/.ssh/known_hosts
        StrictHostKeyChecking accept-new
    '';

    # (1) リモートログイン (sshd) を有効にする (FIX-18)。中継エージェントは
    # 127.0.0.1:22 へつなぐため、sshd が止まっていると中継が成立しない。
    # systemsetup -setremotelogin は権限不足で黙って失敗するため使わず、
    # launchctl で有効にし、22番が開いたことを確かめてから終わる
    system.activationScripts.postActivation.text = lib.mkAfter ''
      /bin/launchctl enable system/com.openssh.sshd
      /bin/launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
      ok=0
      for _ in $(/usr/bin/seq 1 15); do
        if /usr/bin/nc -z 127.0.0.1 22 2>/dev/null; then
          ok=1
          break
        fi
        /bin/sleep 1
      done
      if [ "$ok" != 1 ]; then
        echo "quartetto-relay: sshd が 22 番で待ち受けていません" >&2
        exit 1
      fi
      # qt-gui-run を利用ユーザーの ~/.local/bin に置く (FIX-27 (6))。
      # claude-local の start が GUI セッションでの起動をこの補助スクリプトに
      # 寄せており、SSH から決まったパスで呼べる必要がある
      /bin/mkdir -p ${homeDir}/.local/bin
      /bin/ln -sf ${quartettoQtGuiRun}/bin/qt-gui-run ${homeDir}/.local/bin/qt-gui-run
    '';

    # (2) CA の公開鍵を sshd が読む場所に置く。Hub が発行する証明書はこの鍵で
    # 署名されており、TrustedUserCAKeys でこの鍵を信頼して初めて受け入れられる (KEY-01)
    environment.etc."ssh/quartetto_ca.pub".source = ../files/quartetto_ca.pub;
    # 本体の sshd_config は汚さず、Include 先のドロップインで信頼設定だけを足す
    environment.etc."ssh/sshd_config.d/200-quartetto.conf".text = ''
      TrustedUserCAKeys /etc/ssh/quartetto_ca.pub
    '';

    # (3) エージェントのトークンは sops で自ホストの分だけ復号する (RL-08)。
    # 相手ホストの分まで置くと漏れたときの影響が広がるため、自分の分だけにする
    sops.secrets.${tokenSecret} = {
      # エージェントは利用ユーザーの LaunchAgent で動くため、そのユーザーが読めるようにする
      owner = username;
      # トークンは Hub への接続鍵なので、他ユーザーから読めないようにする
      mode = "600";
    };

    # (4) 中継エージェントをログイン時に常駐させる (RL-01)。
    # 落ちたときも launchd が起こし直し、Hub への外向き接続を保ち続ける
    launchd.user.agents.quartetto-relay-agent = {
      serviceConfig = {
        # 本体は quartetto の flake が出す実行ファイル (RL-10)。
        # FIX-28: 再起動の直後は sops-nix がまだトークンを置いていないことが
        # あるため、起動スクリプトでも最大 10 分待ってから本体を起動する
        # (本体側でも待つが、launchd の再起動の繰り返しを避けるため二重に備える)
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            i=0
            while [ ! -e ${config.sops.secrets.${tokenSecret}.path} ] && [ "$i" -lt 600 ]; do
              /bin/sleep 1
              i=$((i+1))
            done
            exec ${quartettoRelayAgent}/bin/quartetto-relay-agent
          ''
        ];
        RunAtLoad = true;
        KeepAlive = true;
        EnvironmentVariables = {
          QT_HUB_URL = relay.hubUrl;
          QT_RELAY_HOST = relay.host;
          # トークンはファイル経由で渡す (FIX-15)。環境変数に平文を置かない
          QT_RELAY_TOKEN_FILE = config.sops.secrets.${tokenSecret}.path;
        };
        StandardOutPath = "${homeDir}/Library/Logs/quartetto-relay-agent.log";
        StandardErrorPath = "${homeDir}/Library/Logs/quartetto-relay-agent.log";
      };
    };

    # (5) quartetto-worker を利用ユーザーに入れる (FIX-30 (1b), R-36)。
    # ローカルの Worker セッションで W-05 などの規律を効かせるため、marketplace
    # (void2610/quartetto) の最新の quartetto-worker をログイン時にユーザー単位で入れ直す。
    # marketplace の取得は GitHub への SSH を使うため、鍵の末尾改行の修正
    # (fix-ssh-key-newline) と競合したら間を置いてやり直す。
    launchd.user.agents.quartetto-worker-plugin = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            # gh は利用ユーザーのプロファイルにあり、非公開の marketplace の取得で git の認証に使う
            export PATH="/opt/homebrew/bin:/etc/profiles/per-user/${username}/bin:${homeDir}/.local/node24/bin:/usr/bin:/bin"
            CLAUDE=/opt/homebrew/bin/claude
            # claude.ai から同期された quartetto-worker@synced と取り違えないよう、marketplace 付きの ID で見る
            PLUGIN=quartetto-worker@quartetto
            [ -x "$CLAUDE" ] || exit 0
            for attempt in 1 2 3 4 5; do
              refreshed=0
              if "$CLAUDE" plugin marketplace list 2>/dev/null | grep -q "quartetto"; then
                "$CLAUDE" plugin marketplace update quartetto >/dev/null 2>&1 && refreshed=1
              else
                "$CLAUDE" plugin marketplace add void2610/quartetto >/dev/null 2>&1 && refreshed=1
              fi
              if [ "$refreshed" = 1 ]; then
                # plugin.json の version が変わらないため plugin update は新しいコミットを取らない。入れ直して最新にする
                if "$CLAUDE" plugin list 2>/dev/null | grep -q "$PLUGIN"; then
                  "$CLAUDE" plugin uninstall "$PLUGIN" --scope user >/dev/null 2>&1
                fi
                "$CLAUDE" plugin install "$PLUGIN" --scope user >/dev/null 2>&1
                if "$CLAUDE" plugin list 2>/dev/null | grep -q "$PLUGIN"; then
                  exit 0
                fi
              fi
              /bin/sleep 30
            done
            exit 0
          ''
        ];
        RunAtLoad = true;
        StandardOutPath = "${homeDir}/Library/Logs/quartetto-worker-plugin.log";
        StandardErrorPath = "${homeDir}/Library/Logs/quartetto-worker-plugin.log";
      };
    };

  };
}
