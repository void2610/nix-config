{
  power.sleep = {
    # サーバー用途なので、本体は自動スリープさせない。
    computer = "never";
    # 内蔵ディスプレイだけは消灯して、発熱と消費電力を抑える。
    display = 10;
    harddisk = "never";
    allowSleepByPowerButton = false;
  };

  system.activationScripts.serverPowerSettings.text = ''
    # Closed-lid persistence and a few power flags are not exposed as nix-darwin
    # options, so keep them under declarative activation.
    /usr/bin/pmset -a disablesleep 1
    /usr/bin/pmset -a powernap 0
    /usr/bin/pmset -a autorestart 1
    /usr/bin/pmset -a womp 1
  '';
}
