# home-manager/profiles/

用途別の差分を定義する。全プロファイル共通の設定は `../modules/` に置く。

## ファイル一覧

| ファイル | 対象ホスト | 内容 |
|---|---|---|
| `game.nix` | Macintosh, game-dev | 現状は空（基本設定のみ） |
| `work.nix` | PCmac24055 | `modules/melchior/` をインポート |
| `server.nix` | server-node | 現状は空（基本設定のみ） |

## flake.nix との関係

`flake.nix` の `mkDarwinConfiguration` が `profile` 引数を受け取り、
対応するプロファイルファイルを home-manager に渡す。
