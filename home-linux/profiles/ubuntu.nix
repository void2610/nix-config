{ pkgs, lib, ... }:
{
  # 非 NixOS の Linux で nix profile の PATH / XDG セッション統合を有効にする。
  targets.genericLinux.enable = true;

  # nix で導入したフォントを fontconfig に認識させる。
  fonts.fontconfig.enable = true;

  # Mason 版 tree-sitter-cli は Ubuntu 22.04 の GLIBC 2.35 で動かないため nix 版に差し替える。
  home.activation.linkNixTreeSitterForMason = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mason_ts="$HOME/.local/share/nvim/mason/bin/tree-sitter"
    if [ -e "$mason_ts" ] || [ -L "$mason_ts" ]; then
      ln -sf "${pkgs.tree-sitter}/bin/tree-sitter" "$mason_ts"
    fi
  '';
}
