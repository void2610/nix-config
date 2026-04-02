# nix-darwin/modules/

macOS システム設定の共通モジュール群。

- `base.nix`: 他モジュールをまとめてインポートする中間層
- `defaults.nix`: macOS UI/UX 設定
- `nix-core.nix`: Nix 設定
- `security.nix`: セキュリティ設定
- `secrets.nix`: sops-nix による secrets 配置
- `homebrew.nix`: Homebrew パッケージ管理（profile 別に分岐）
- `melchior/`: Melchior 開発用 C++ ビルド依存（work-dev のみ）
