# Conductor が nix-config の反映を人間の手なしで行えるよう、darwin-rebuild だけをパスワードなしの sudo で許す (FIX-32。server と game 専用)
{ config, ... }:
let
  username = config.system.primaryUser;
in
{
  # 対象は darwin-rebuild の実行ファイルだけに限り、ほかのコマンドや ALL には広げない
  security.sudo.extraConfig = ''
    ${username} ALL=(root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
  '';
}
