# nix-darwin/

macOS のシステム設定層。

- `hosts/`: ホスト固有の値（ホスト名・ユーザー名）
- `mk-configurations.nix`: nix-darwin / home-manager を束ねて flake 用の `darwinConfigurations` を構築
- `modules/`: 全ホスト共通のシステムモジュール（Homebrew・セキュリティ・macOS デフォルト等）

ホスト定義は `hosts/default.nix` に集約し、`profile` も含めて一元管理する。
各ホストは `base.nix` と `homebrew.nix` をインポートするだけで共通設定が全て入る構造。
プロジェクト固有の依存は `modules/<project>/` として分離している。
