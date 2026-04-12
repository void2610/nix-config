{
  # スリープ抑止は Amphetamine 側でその時々に切り替えたい。
  # Nix から固定化すると一時停止や解除がやりづらいため、server では OS の補助設定だけ残す。
  system.activationScripts.serverPowerSettings.text = ''
    # サーバー運用中の予期しない停止から自動復旧させたいので、自動再起動を有効にする。
    /usr/bin/pmset -a autorestart 1

    # 画面を開かなくてもネットワーク越しに起動できるよう、Wake on LAN を維持する。
    /usr/bin/pmset -a womp 1
  '';
}
