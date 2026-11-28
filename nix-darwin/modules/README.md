# nix-darwin/modules/

macOS システム設定の共通モジュール群。

- `base.nix`: 他モジュールをまとめてインポートする中間層
- `defaults.nix`: macOS UI/UX 設定
- `nix-core.nix`: Nix 設定
- `security.nix`: セキュリティ設定
- `secrets.nix`: sops-nix による secrets 配置
- `homebrew.nix`: Homebrew パッケージ管理（profile 別に分岐）
- `melchior/`: Melchior 開発用 C++ ビルド依存（work のみ）
- `claude-desktop.nix`: Claude デスクトップアプリの cask と常駐の LaunchAgent（game・server）。アプリは自己更新で終了したあと ShipIt が launchd の外で起動し直すので、本体を直接起動するだけでは更新のたびに見張りが外れる。LaunchAgent は見張りのスクリプトを動かし、本体が動いていれば待ち、いなければ起動する
- `tailscale.nix`: nixpkgs の tailscaled を launchd で常駐させる（game・server）。GUI 版は sandbox 制約で Tailscale SSH を受けられないため、この 2 台は cask の tailscale-app を入れない
- `quartetto-conductor.nix`: quartetto の Conductor を常駐させる LaunchAgent（server のみ）。クラウドのセッションにはバイパスのモードがないため、`~/Documents/GitHub/quartetto` で `claude remote-control --permission-mode bypassPermissions --name Conductor` を動かす。起動前に sops のトークンとクローンを待ち、フォルダの信頼を `~/.claude.json` に書く。Hub への認証は中継エージェントと同じ自ホストのトークン（`QT_HUB_TOKEN_FILE`）を使う。ログは `~/Library/Logs/quartetto-conductor.log`
