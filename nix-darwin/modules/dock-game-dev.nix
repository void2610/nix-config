{ config, ... }:
let
  userHome = config.users.users.${config.system.primaryUser}.home;
in
{
  system.defaults.dock = {
    # 開発と日常利用で頻繁に触るアプリを左からの導線で固定する。
    # 音楽系は Spotify と Apple Music を隣接させ、切り替え時に Dock 上で迷わないようにする。
    persistent-apps = [
      { app = "/Applications/Zed.app"; }
      { app = "/Applications/Discord.app"; }
      { app = "/Applications/Arc.app"; }
      { app = "/Applications/Spotify.app"; }
      { app = "/System/Applications/Music.app"; }
      { app = "/Applications/GitHub Desktop.app"; }
      { app = "/Applications/Rider.app"; }
      { app = "/System/Applications/System Settings.app"; }
      { app = "/Applications/Warp.app"; }
    ];

    # Downloads を Dock に残しておくと、スクリーンショットや書き出し結果へ最短で辿れる。
    # 日付順の stack/fan 表示にして、新しいファイルを目視で見つけやすくする。
    persistent-others = [
      {
        folder = {
          path = "${userHome}/Downloads";
          arrangement = "date-modified";
          displayas = "stack";
          showas = "fan";
        };
      }
    ];
  };
}
