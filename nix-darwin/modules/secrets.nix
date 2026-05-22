{ config, lib, profile, ... }:
let
  username = config.system.primaryUser;
  homeDir = config.users.users.${username}.home;
  secretsFile = ../../secrets/common.yaml;
  hasSecretsFile = builtins.pathExists secretsFile;
in
{
  sops = {
    age.keyFile = "${homeDir}/.config/sops/age/keys.txt";
    defaultSopsFormat = "yaml";
  } // lib.optionalAttrs hasSecretsFile {
    defaultSopsFile = secretsFile;
    secrets = {
      ssh_config = {
        path = "${homeDir}/.ssh/config";
        owner = username;
        mode = "600";
      };

      ssh_id_github_rsa = {
        path = "${homeDir}/.ssh/id_github_rsa";
        owner = username;
        mode = "600";
      };

      ssh_id_rsa = {
        path = "${homeDir}/.ssh/id_rsa";
        owner = username;
        mode = "600";
      };

      ssh_mirai_server = {
        path = "${homeDir}/.ssh/mirai-server";
        owner = username;
        mode = "600";
      };
    } // lib.optionalAttrs (profile == "server") {
      # server だけが GitHub Actions runner を持つため、registration token もホスト限定で置く。
      # 他 profile に配ると不要な権限面が広がるため、server のときだけ復号対象にする。
      github_runner_void2610_org_token = {
        # runner 登録時に常用ユーザーの service から読ませるため、owner を primaryUser に合わせる。
        # root 所有のままだと launchd 側の読み取り条件が環境差分になりやすいため明示する。
        owner = username;
        # 通常のユーザー運用と同じ staff グループに揃えて、他 secret と扱いを一致させる。
        # 個別グループを増やさずに権限制御を簡潔に保つため staff を使う。
        group = "staff";
        # registration token は再登録に使えるため、他ユーザーから読めないよう最小権限に絞る。
        # 誤読取を避けるため 600 固定にする。
        mode = "600";
      };
    };
  };

  system.activationScripts.postActivation.text = lib.mkAfter ''
    /bin/mkdir -p ${homeDir}/.ssh
    /usr/sbin/chown ${username}:staff ${homeDir}/.ssh
    /bin/chmod 700 ${homeDir}/.ssh
    /bin/mkdir -p ${homeDir}/.config/sops/age
    /usr/sbin/chown ${username}:staff ${homeDir}/.config/sops/age
    /bin/chmod 700 ${homeDir}/.config/sops/age

    # sops-nix が SSH 秘密鍵の末尾改行を削除するため、シンボリックリンクを
    # 末尾改行付きの実ファイルに置き換える (darwin-rebuild 経路)。
    # 再起動経路は launchd daemon (fix-ssh-key-newline) でカバーする。
    for key in id_github_rsa id_rsa mirai-server; do
      target="${homeDir}/.ssh/$key"
      if [ -L "$target" ]; then
        real=$(readlink "$target")
        /bin/unlink "$target"
        /bin/cat "$real" > "$target"
        /bin/echo "" >> "$target"
        /usr/sbin/chown ${username}:staff "$target"
        /bin/chmod 600 "$target"
      fi
    done
  '';

  # 再起動時は sops-nix が launchd 経由で /run/secrets を非同期に再生成するため、
  # postActivation の修正は走らず symlink のまま残ってしまう。boot 時にも同等処理を
  # 走らせるため、独立した system daemon を RunAtLoad で配置する。
  launchd.daemons.fix-ssh-key-newline = {
    serviceConfig = {
      Label = "com.local.fix-ssh-key-newline";
      RunAtLoad = true;
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          # sops-nix の secret 配置と race するため、最大 30 秒ポーリングで待つ。
          i=0
          while [ "$i" -lt 30 ] && [ ! -e /run/secrets/ssh_id_github_rsa ]; do
            /bin/sleep 1
            i=$((i+1))
          done
          for key in id_github_rsa id_rsa mirai-server; do
            target="${homeDir}/.ssh/$key"
            if [ -L "$target" ]; then
              real=$(/usr/bin/readlink "$target")
              /bin/unlink "$target"
              /bin/cat "$real" > "$target"
              /bin/echo "" >> "$target"
              /usr/sbin/chown ${username}:staff "$target"
              /bin/chmod 600 "$target"
            fi
          done
        ''
      ];
      StandardOutPath = "/var/log/fix-ssh-key-newline.log";
      StandardErrorPath = "/var/log/fix-ssh-key-newline.log";
    };
  };
}
