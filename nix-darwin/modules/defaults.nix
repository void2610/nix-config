{
  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.4;
      magnification = true;
      largesize = 62;
      tilesize = 59;
      mineffect = "scale";
      minimize-to-application = false;
      launchanim = true;
      show-process-indicators = true;
      show-recents = false;
      mru-spaces = false;
      expose-group-apps = true;
      showMissionControlGestureEnabled = true;
      showAppExposeGestureEnabled = false;
      showDesktopGestureEnabled = false;
      showLaunchpadGestureEnabled = false;
      wvous-tl-corner = 2;
      wvous-tr-corner = 2;
      wvous-bl-corner = 11;
      wvous-br-corner = 4;
    };

    finder = {
      AppleShowAllFiles = true;
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv";
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      _FXSortFoldersFirst = true;
      _FXSortFoldersFirstOnDesktop = true;
      _FXShowPosixPathInTitle = false;
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowScrollBars = "Automatic";
      _HIHideMenuBar = false;
      AppleWindowTabbingMode = "always";
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      AppleKeyboardUIMode = 3;
      "com.apple.trackpad.forceClick" = true;
      "com.apple.trackpad.scaling" = 3.0;
      "com.apple.swipescrolldirection" = true;
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticDashSubstitutionEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = true;
      NSAutomaticSpellingCorrectionEnabled = true;
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      AppleTemperatureUnit = "Celsius";
    };

    screencapture = {
      location = "~/Downloads";
      target = "file";
      disable-shadow = false;
      include-date = true;
      show-thumbnail = true;
    };

    menuExtraClock = {
      FlashDateSeparators = false;
      IsAnalog = false;
      Show24Hour = true;
      ShowDate = 1;
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;
      ShowSeconds = false;
    };

    spaces = {
      spans-displays = false;
    };

    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };
  };
}
