{ pkgs, ... }:
{
  programs.openclaw = {
    enable = true;
    # OpenClaw が最低限要求する documents 群を repo 管理にする。
    documents = ./server-openclaw-documents;

    # まずはローカル gateway を常駐させる最小構成にして、
    # bot や provider の接続情報は server 側で順次足す。
    config = {
      gateway.mode = "local";
    };

    # 既存の Home Manager / system 側で入れている CLI は重複導入しない。
    excludeTools = [
      "git"
      "jq"
      "ripgrep"
    ];

    instances.default = {
      enable = true;
      # batteries-included package。macOS app と gateway をまとめて扱う。
      package = pkgs.openclaw;
    };
  };
}
