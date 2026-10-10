{ config, ... }:
let
  # Licensing Client の named pipe 名は Unity 側が "Unity-LicenseClient-<user>" で固定しているため primaryUser から組み立てる
  user = config.system.primaryUser;
in
{
  # Unity Hub を起動していないと CI の Unity が Licensing Client を自分で spawn し、ステップの stdio を継承したまま常駐してパイプが閉じず runner が止まる。ログイン時にセッション側で先に起動しておく
  launchd.user.agents.unity-licensing-client = {
    serviceConfig = {
      ProgramArguments = [
        "/Applications/Unity Hub.app/Contents/Frameworks/UnityLicensingClient_V1.app/Contents/MacOS/Unity.Licensing.Client"
        "--namedPipe"
        "Unity-LicenseClient-${user}"
        "--cloudEnvironment"
        "production"
      ];
      RunAtLoad = true;
      # 既に別の Client が pipe を持っていると即終了するので KeepAlive ではなく定期再試行で常駐を保つ
      StartInterval = 300;
      StandardOutPath = "/Users/${user}/Library/Logs/unity-licensing-client.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/unity-licensing-client.log";
    };
  };
}
