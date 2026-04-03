{ config, ... }:
let
  userHome = config.users.users.${config.system.primaryUser}.home;
in
{
  system.defaults.dock = {
    persistent-apps = [
      { app = "/Applications/Zed.app"; }
      { app = "/Applications/Discord.app"; }
      { app = "/Applications/Arc.app"; }
      { app = "/Applications/Spotify.app"; }
      { app = "/Applications/GitHub Desktop.app"; }
      { app = "/Applications/Rider.app"; }
      { app = "/System/Applications/System Settings.app"; }
      { app = "/Applications/Warp.app"; }
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
