# nix-darwin/hosts/

ホスト固有の値のみを定義する。共通設定は `../modules/` に置く。

## ファイル一覧

| ファイル | ホスト名 | profile | 追加モジュール |
|---|---|---|---|
| `Macintosh.nix` | Macintosh | game | - |
| `game-dev.nix` | game-dev | game | - |
| `work-dev.nix` | PCmac24055 | work | `modules/melchior/` |
| `server-node.nix` | server-node | server | - |

## 新しいホストを追加するとき

1. このディレクトリに `<host-name>.nix` を作成
2. `../../flake.nix` の `darwinConfigurations` に追加
3. 必要なら専用モジュールを `../modules/` に作成してインポート
