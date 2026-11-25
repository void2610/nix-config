# nix-darwin/modules/

macOS システム設定の共通モジュール群。

- `base.nix`: 他モジュールをまとめてインポートする中間層
- `defaults.nix`: macOS UI/UX 設定
- `nix-core.nix`: Nix 設定
- `security.nix`: セキュリティ設定
- `secrets.nix`: sops-nix による secrets 配置
- `homebrew.nix`: Homebrew パッケージ管理（profile 別に分岐）
- `melchior/`: Melchior 開発用 C++ ビルド依存（work のみ）
- `claude-desktop.nix`: Claude デスクトップアプリの cask と常駐の LaunchAgent（game・server）。アプリは自己更新で終了コード 0 で終わって自分で起動し直すため、KeepAlive は異常終了だけを拾う。自己更新で起動し直した後の本体は launchd の管理外になり、次のログインで管理下に戻る
