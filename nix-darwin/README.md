# nix-darwin/

macOS のシステム設定層。

- `hosts/`: ホスト固有の値（ホスト名・ユーザー名）
- `modules/`: 全ホスト共通のシステムモジュール（Homebrew・セキュリティ・macOS デフォルト等）

ホストは `base.nix` と `homebrew.nix` をインポートするだけで共通設定が全て入る構造。
プロジェクト固有の依存は `modules/<project>/` として分離している。
