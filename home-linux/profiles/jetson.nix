{ pkgs, lib, ... }:
{
  # 非 NixOS の Linux で nix profile の PATH / XDG セッション統合を有効にする。
  targets.genericLinux.enable = true;

  # 共有ロボット機 (Jetson) はディスクが逼迫しているため、nvim + lazygit に絞る。
  # LSP/formatter は Mason が nvim 側で導入するので、clang-tools 等のツールチェーンは持たない。
  home.packages = lib.mkForce (
    with pkgs;
    [
      neovim
      lazygit
      ripgrep
      fd
      tree-sitter
      nodejs_22
      uv
      bat
      eza
      delta
      jq
      just
      xclip
      pet
    ]
  );

  # Mason 版 tree-sitter-cli が古い GLIBC で動かないため nix 版に差し替える (ubuntu profile と同じ)。
  home.activation.linkNixTreeSitterForMason = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mason_ts="$HOME/.local/share/nvim/mason/bin/tree-sitter"
    if [ -e "$mason_ts" ] || [ -L "$mason_ts" ]; then
      ln -sf "${pkgs.tree-sitter}/bin/tree-sitter" "$mason_ts"
    fi
  '';
}
