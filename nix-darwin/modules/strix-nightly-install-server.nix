{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.system.primaryUser;
  repo = "/Users/${user}/Documents/GitHub/strix";
  script = pkgs.writeShellScript "strix-nightly-install" ''
    set -u
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin
    DEVICE=9C6866FC-D294-573E-BB8B-4106CC0E01F6
    DEST="platform=iOS,id=00008140-001C61C436A2801C"
    STAMP=$(date +%Y%m%d)
    FLAG="/tmp/strix-nightly-install.success-$STAMP"

    # その日すでに成功していれば、以降の毎時トリガーは打ち切る。
    if [ -f "$FLAG" ]; then
      echo "$(date '+%F %T') 本日は成功済みのためスキップ"
      exit 0
    fi

    cd ${repo} || { echo "$(date '+%F %T') リポジトリが見つかりません: ${repo}"; exit 1; }

    # 古いチェックアウトのまま入れると手元から入れた新しい版を巻き戻すため、main に追従できない回は入れない
    if ! git pull --ff-only --quiet origin main; then
      echo "$(date '+%F %T') main の取り込みに失敗（次回リトライ）"
      exit 1
    fi

    # Xcode は期限内のプロファイルを使い回し、入れ直しても 7 日の期限は延びないため、期限まで 2 日を切ったら消して作り直させる
    limit=$(($(date +%s) + 2 * 86400))
    for profile in "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"/*.mobileprovision; do
      [ -e "$profile" ] || continue
      plist=$(openssl smime -inform der -verify -noverify -in "$profile" 2>/dev/null) || continue
      case "$(plutil -extract Entitlements.application-identifier raw -o - - <<<"$plist" 2>/dev/null)" in
        *.void2610.Strix | *.void2610.Strix.*) ;;
        *) continue ;;
      esac
      expires=$(plutil -extract ExpirationDate raw -o - - <<<"$plist")
      if [ "$(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$expires" +%s)" -lt "$limit" ]; then
        echo "$(date '+%F %T') 期限の近いプロファイルを削除: ''${profile##*/} ($expires)"
        rm -f "$profile"
      fi
    done

    echo "$(date '+%F %T') ビルド開始: $(git log --oneline -1)"
    # 有効な証明書が無いと -allowProvisioningUpdates が新しく作り、共有中の証明書を失効させて手元の Mac で入れたアプリが起動しなくなる (apple-development-signing.nix)
    if ! xcodebuild -project Strix.xcodeproj -scheme Strix \
          -destination "$DEST" -configuration Debug \
          -allowProvisioningUpdates build; then
      echo "$(date '+%F %T') ビルド失敗（実機ロック/未接続の可能性、次回リトライ）"
      exit 1
    fi

    APP=$(find "$HOME/Library/Developer/Xcode/DerivedData"/Strix-*/Build/Products/Debug-iphoneos -maxdepth 1 -name Strix.app 2>/dev/null | head -1)
    if [ -z "$APP" ]; then
      echo "$(date '+%F %T') Strix.app が見つかりません"
      exit 1
    fi

    if xcrun devicectl device install app --device "$DEVICE" "$APP"; then
      expires=$(openssl smime -inform der -verify -noverify -in "$APP/embedded.mobileprovision" 2>/dev/null | plutil -extract ExpirationDate raw -o - - 2>/dev/null)
      echo "$(date '+%F %T') インストール成功: $APP (プロファイルの期限 $expires)"
      touch "$FLAG"
      # 数日以上前の成功フラグは掃除する。
      find /tmp -maxdepth 1 -name 'strix-nightly-install.success-*' -mtime +3 -delete 2>/dev/null
      exit 0
    else
      echo "$(date '+%F %T') インストール失敗（次回リトライ）"
      exit 1
    fi
  '';
in
{
  # 無料 Apple ID の署名は 7 日で切れるため、iPhone が同じネットワークにいる夜間に毎日ビルドし直して入れ直す
  launchd.user.agents.strix-nightly-install = {
    serviceConfig = {
      ProgramArguments = [ "${script}" ];
      StartCalendarInterval = map (hour: {
        Hour = hour;
        Minute = 0;
      }) (lib.range 0 7);
      RunAtLoad = false;
      KeepAlive = false;
      StandardOutPath = "/tmp/strix-nightly-install.out.log";
      StandardErrorPath = "/tmp/strix-nightly-install.err.log";
    };
  };
}
