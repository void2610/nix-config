{ config, ... }:
let
  userHome = config.users.users.${config.system.primaryUser}.home;
in
{
  system.defaults.dock = {
    # 存在しないアプリを並べると Dock に「?」アイコンが残るため、入っているアプリだけを置く。
    persistent-apps = [
      { app = "/Applications/Discord.app"; }
      { app = "/Applications/Arc.app"; }
      { app = "/Applications/Spotify.app"; }
      { app = "/System/Applications/System Settings.app"; }
      { app = "/Applications/Ghostty.app"; }
    ];

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
