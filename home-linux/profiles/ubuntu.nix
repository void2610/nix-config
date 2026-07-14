{ ... }:
{
  # 非 NixOS の Linux で nix profile の PATH / XDG セッション統合を有効にする。
  targets.genericLinux.enable = true;

  # nix で導入したフォントを fontconfig に認識させる。
  fonts.fontconfig.enable = true;
}
