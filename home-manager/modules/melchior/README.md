# melchior/ （home-manager）

[Melchior](https://github.com/AKARI-Inc/melchior) の Python バインディングに必要なパッケージを定義する。
`work` profile（= `work-dev` ホスト）のみがインポートする。

## 管理パッケージ

| パッケージ | 用途 |
|---|---|
| `numpy` | 数値計算 |
| `scipy` | 科学計算 |
| `ezdxf` | DXF ファイル入出力 |
| `shapely` | 2D ジオメトリ処理 |
| `numba` | JIT コンパイル |

## 仕組み

`python312.withPackages` で Python 3.12 環境を構築し、`PYTHONPATH` に site-packages のパスを設定する。

Melchior は Python を C++ に埋め込んで使用しており、起動時に `PYTHONPATH` を読んでパッケージを検索する。
`withPackages` のラッパースクリプトは埋め込み時には実行されないため、`PYTHONPATH` の明示的な設定が必要。

## パッケージを追加するとき

`default.nix` の `withPackages` リストに追記し、`darwin-rebuild switch` を実行する。

```nix
melchiorPython = pkgs.python312.withPackages (ps: with ps; [
  numpy
  scipy
  ezdxf
  shapely
  numba
  # ここに追記
]);
```
