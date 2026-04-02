# home-manager/modules/melchior/

[Melchior](https://github.com/AKARI-Inc/melchior) の Python バインディングに必要なパッケージ。
`work` profile（= `work-dev` ホスト）のみがインポートする。

`python312.withPackages` で Python 環境を構築し、`PYTHONPATH` に設定する。
Melchior は Python を C++ に埋め込むため、`PYTHONPATH` の明示的な設定が必要。

C++ ビルド依存は `nix-darwin/modules/melchior/` で管理している。
