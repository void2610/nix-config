{ config, lib, ... }:
let
  appName = "Open in Neovim";
  bundleId = "local.open-in-neovim";
  appPath = "${config.home.homeDirectory}/Applications/${appName}.app";
  lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister";

  # Markdown の UTI。macOS は .md をこの型に解決する。
  markdownUti = "net.daringfireball.markdown";

  # Ghostty は macOS で IPC CLI を持たず (`+new-window` は非対応)、`open -na` は別インスタンスを
  # 立てて即終了するため、既存インスタンスへ届く手段は AppleScript の new tab しかない。
  dropletSource = ''
    on openFile(posixPath)
    	tell application "Ghostty"
    		activate
    		set cfg to new surface configuration
    		-- command は直接 exec されログインシェルの初期化が飛ぶため、nvim や macism を解決できるよう zsh -l を挟む。
    		set command of cfg to "/bin/zsh -lc " & quoted form of ("exec nvim " & quoted form of posixPath)
    		-- new tab は in 指定が無いと -1708 で失敗する。
    		if (count of windows) is 0 then
    			new window with configuration cfg
    		else
    			new tab in front window with configuration cfg
    		end if
    	end tell
    end openFile

    on open theFiles
    	repeat with f in theFiles
    		openFile(POSIX path of f)
    	end repeat
    end open
  '';

  # duti は既存の割り当てを無言で失敗して上書きできないため、LaunchServices API を直接呼ぶ。
  setDefaultHandlerSwift = ''
    import CoreServices
    import Foundation
    let uti = "${markdownUti}" as NSString as CFString
    let bid = "${bundleId}" as NSString as CFString
    guard LSSetDefaultRoleHandlerForContentType(uti, .all, bid) == 0 else { exit(1) }
  '';
in
{
  home.file.".local/share/open-in-neovim/droplet.applescript".text = dropletSource;
  home.file.".local/share/open-in-neovim/set-default-handler.swift".text = setDefaultHandlerSwift;

  home.activation.openInNeovim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    src="${config.home.homeDirectory}/.local/share/open-in-neovim/droplet.applescript"
    run rm -rf ${lib.escapeShellArg appPath}
    run /usr/bin/osacompile -o ${lib.escapeShellArg appPath} "$src"
    run /usr/bin/plutil -replace CFBundleIdentifier -string ${bundleId} ${lib.escapeShellArg "${appPath}/Contents/Info.plist"}
    run /usr/bin/plutil -replace CFBundleName -string ${lib.escapeShellArg appName} ${lib.escapeShellArg "${appPath}/Contents/Info.plist"}
    run /usr/bin/codesign --force --deep --sign - ${lib.escapeShellArg appPath}
    run ${lsregister} -f ${lib.escapeShellArg appPath}

    # swift の起動が重いため、既定が既に自分なら呼ばない。
    current=$(/usr/bin/plutil -convert json -o - "${config.home.homeDirectory}/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist" 2>/dev/null \
      | /usr/bin/grep -o '"LSHandlerContentType":"${markdownUti}","LSHandlerRoleAll":"[^"]*"' \
      | /usr/bin/sed 's/.*"LSHandlerRoleAll":"\([^"]*\)"/\1/') || true
    if [ "$current" != "${bundleId}" ]; then
      run /usr/bin/swift "${config.home.homeDirectory}/.local/share/open-in-neovim/set-default-handler.swift"
    fi
  '';
}
