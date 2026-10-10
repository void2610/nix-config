{
  config,
  pkgs,
  ...
}:
let
  user = config.system.primaryUser;
  # `cloudflared tunnel create shinkyo` で作ったトンネル。ID だけでは接続できず、鍵は sops の認証情報にある
  tunnelId = "604f19bc-1157-4270-b64f-525dc343ce7d";
  # ~/.cloudflared/config.yml を手で置かず、公開するホスト名と転送先をここで宣言する
  configFile = pkgs.writeText "cloudflared-shinkyo.yml" ''
    tunnel: ${tunnelId}
    credentials-file: ${config.sops.secrets.cloudflared_shinkyo_credentials.path}
    ingress:
      # shinkyo の画面は 127.0.0.1 にだけ bind しているので、トンネルから中継する (入れる人は Cloudflare Access で限る)
      - hostname: shinkyo.void2610.dev
        service: http://127.0.0.1:8787
      # 知らないホスト名で来たリクエストは中継しない
      - service: http_status:404
  '';
in
{
  # `cloudflared service install` の plist は引数に tunnel run が無く起動しても即終了するため、自前で常駐を宣言する
  launchd.user.agents.cloudflared = {
    serviceConfig = {
      # 本体は Homebrew の brews で入れたもの (homebrew.nix の server)。更新も brew に任せるので自動更新は切る
      ProgramArguments = [
        "/opt/homebrew/bin/cloudflared"
        "tunnel"
        "--no-autoupdate"
        "--config"
        "${configFile}"
        "run"
      ];
      # ログイン時に起動し、落ちても張り直して公開が止まらないようにする
      RunAtLoad = true;
      KeepAlive = true;
      # 接続の失敗を後から追えるよう、ユーザーのログ置き場に残す
      StandardOutPath = "/Users/${user}/Library/Logs/cloudflared.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/cloudflared.log";
    };
  };
}
