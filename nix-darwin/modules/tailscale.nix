{ pkgs, ... }:
{
  # macOS の GUI 版では Tailscale SSH の受け側が sandbox 制約で動かない。
  # open source CLI と tailscaled を launchd 管理に切り替えて SSH 受付を有効にする。
  services.tailscale = {
    # server ホストではログイン前から Tailnet 接続を維持したいため常駐 daemon を有効にする。
    enable = true;
    # 利用パッケージを明示して、Homebrew cask ではなく nixpkgs 版の open source CLI を使う。
    package = pkgs.tailscale;
  };
}
