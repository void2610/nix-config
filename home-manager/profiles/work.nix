{ pkgs, ... }:
let
  # Melchior の実リポジトリ位置をここで固定しておく。
  # `mel` 実行時に毎回同じ作業ツリーへ移動させ、別ディレクトリから誤って入って
  # configure や `site-packages` の出力先がぶれる事故を防ぐため。
  melchiorRepo = "/Users/shuya.izumi/Documents/GitHub/melchior";

  # `dev-shell.nix` が読む補助スクリプト群もまとめて store へ渡す。
  # 単一ファイルだけを `nix-shell` に渡すと `./env.sh` などの相対参照が欠け、
  # 評価時に `path '/nix/store/env.sh' does not exist` で落ちるため。
  melchiorShellDir = builtins.toString ../../pkgs/melchior;

  # `nix-shell` に渡す nixpkgs 参照も文字列へ固定する。
  # `path` 値のまま埋め込むと flake 評価時に余計な path context が残りやすく、
  # `darwin-rebuild` 中に外部パス解決へ巻き込まれるのを避けたい。
  nixpkgsPath = builtins.toString pkgs.path;
in
{
  programs.zsh.initContent = ''
    # Melchior 用 shell は work profile からだけ入れる。
    # 共有 repo に flake を置かず、個人用の依存と shellHook を外側から注入するため。
    mel() {
      # 先に repo 直下へ寄せ、shellHook が前提にする相対パスを安定させる。
      cd ${melchiorRepo} || return 1

      # nixpkgs は現在の設定が pin しているものを使い、Melchior 用 shell 式だけを評価する。
      # これで `mel` 実行時に derivation の出力パスではなく Nix 式として解釈させ、
      # さらに補助スクリプトも同じ store ディレクトリに含めて相対参照切れを防ぐ。
      nix-shell ${melchiorShellDir}/dev-shell.nix \
        --arg pkgs "(import ${nixpkgsPath} {})" \
        --argstr melchiorRepo "${melchiorRepo}"
    }
  '';
}
