{ config, pkgs, ... }:
let
  username = config.system.primaryUser;
  homeDir = config.users.users.${username}.home;
  keychain = "${homeDir}/Library/Keychains/apple-development.keychain-db";
  identityFile = config.sops.secrets.apple_development_p12.path;
  passwordFile = config.sops.secrets.apple_development_password.path;
  # secret を差し替えたときに agent を読み込み直させるため、暗号化ファイルのハッシュをスクリプトに埋め込む
  secretsHash = builtins.hashFile "sha256" config.sops.defaultSopsFile;
  setupKeychain = pkgs.writeShellScript "apple-development-keychain" ''
    set -euo pipefail
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin
    # secrets: ${secretsHash}

    # sops-nix の secret 配置と race するため、最大 30 秒ポーリングで待つ。
    i=0
    while [ "$i" -lt 30 ] && [ ! -e ${identityFile} ]; do
      sleep 1
      i=$((i + 1))
    done
    password=$(cat ${passwordFile})
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    base64 -D -i ${identityFile} -o "$work/identity.p12"
    sha1=$(openssl pkcs12 -in "$work/identity.p12" -passin "pass:$password" -nokeys -clcerts \
      | openssl x509 -noout -fingerprint -sha1 | cut -d= -f2 | tr -d :)
    # 空のまま grep すると常に一致し、取り込み済みと誤認するため止める
    if [ -z "$sha1" ]; then
      echo "$(date '+%F %T') 証明書を読み取れません" >&2
      exit 1
    fi

    # 証明書の書き出し元のホストには Xcode が作った同じ ID があるため、どのキーチェーンにも無いときだけ入れる
    identities=$(security find-identity -p codesigning)
    if [[ $identities != *"$sha1"* ]]; then
      # 証明書を差し替えたときに古い ID を残さないよう、キーチェーンごと作り直す
      security delete-keychain ${keychain} 2>/dev/null || true
      security create-keychain -p "$password" ${keychain}
      security import "$work/identity.p12" -k ${keychain} -P "$password" -T /usr/bin/codesign
      # 夜間の署名がアクセス許可のダイアログで止まらないよう、codesign に確認なしで鍵を使わせる
      security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$password" ${keychain} >/dev/null
      echo "$(date '+%F %T') 証明書 $sha1 を取り込みました"
    fi

    if [ -e ${keychain} ]; then
      security unlock-keychain -p "$password" ${keychain}
      # 既定の自動ロックがかかると署名のたびにパスワードを求められるため、ロックしない設定にする
      security set-keychain-settings ${keychain}
      mapfile -t keychains < <(security list-keychains -d user | sed -e 's/^ *"//' -e 's/"$//')
      listed=false
      for k in "''${keychains[@]}"; do
        if [ "$k" = ${keychain} ]; then
          listed=true
        fi
      done
      # -s は検索リストを丸ごと置き換えるため、取得に失敗して空のときに login を外さないよう触らない
      if [ "''${#keychains[@]}" -gt 0 ] && [ "$listed" = false ]; then
        security list-keychains -d user -s "''${keychains[@]}" ${keychain}
      fi
    fi
  '';
in
{
  # 無料 Apple ID は有効な開発用証明書を 1 枚しか持てず、Mac ごとに作ると互いに失効させて入れたアプリが起動しなくなるため、sops で配った同じ証明書を使う
  launchd.user.agents.apple-development-keychain = {
    serviceConfig = {
      ProgramArguments = [ "${setupKeychain}" ];
      # 再起動後はキーチェーンがロックされているため、ログイン時に解錠し直す
      RunAtLoad = true;
      StandardOutPath = "${homeDir}/Library/Logs/apple-development-keychain.log";
      StandardErrorPath = "${homeDir}/Library/Logs/apple-development-keychain.log";
    };
  };
}
