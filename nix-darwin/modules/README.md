# nix-darwin/modules/

macOS システム設定の共通モジュール群。各ホストは `base.nix` と `homebrew.nix` をインポートする。

## ファイル一覧

| ファイル / ディレクトリ | 内容 |
|---|---|
| `base.nix` | 他モジュールをまとめてインポートする中間層 |
| `defaults.nix` | macOS UI/UX 設定（Dock・Finder・キーボード等） |
| `nix-core.nix` | Nix 実験的機能の有効化 |
| `security.nix` | Touch ID による sudo 認証 |
| `secrets.nix` | sops-nix による SSH 鍵の復号・配置 |
| `homebrew.nix` | Homebrew パッケージのプロファイル別管理 |
| `melchior/` | Melchior C++ ビルド依存（work-dev のみ） |

## 読み込み関係

```
hosts/work-dev.nix
  └── base.nix
  │     ├── defaults.nix
  │     ├── nix-core.nix
  │     ├── security.nix
  │     └── secrets.nix
  ├── homebrew.nix
  └── melchior/
```
