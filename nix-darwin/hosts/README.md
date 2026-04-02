# nix-darwin/hosts/

ホスト固有の値は `default.nix` の `hosts` attrset にまとめて定義する。
共通設定は `../modules/` に置き、このディレクトリには持ち込まない。

新しい Mac を追加するときは、`default.nix` にホスト情報を追加し、`../../flake.nix` の `darwinConfigurations` に target を追加する。
