{ lib, ... }:
{
  # スリープ抑止は当初 Amphetamine に任せていたが、2026-09-06 に Amphetamine の closed-display モード有効中でも
  # Clamshell Sleep に入り、ランナーが約 16 時間オフラインになった (Amphetamine の assertion は idle sleep 専用で
  # クラムシェルには効かない)。サーバーは常時稼働が前提なので OS 側で確実に固定する。
  # nix-darwin は preActivation/extraActivation/postActivation 等の固定名しか実行しないため、独自名ではなく extraActivation に載せる。
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    # サーバー運用中の予期しない停止から自動復旧させたいので、自動再起動を有効にする。
    /usr/bin/pmset -a autorestart 1

    # 画面を開かなくてもネットワーク越しに起動できるよう、Wake on LAN を維持する。
    /usr/bin/pmset -a womp 1

    # フタを閉じてもスリープさせない。Amphetamine では Clamshell Sleep を防げなかったため OS 側で固定する。
    /usr/bin/pmset -a disablesleep 1
  '';
}
