{ pkgs, ... }:
{
  programs.openclaw = {
    enable = true;
    documents = ./server-openclaw-documents;

    # まずはローカル gateway を常駐させる最小構成にして、
    # bot や provider の接続情報は server 側で順次足す。
    config = {
      gateway.mode = "local";
    };

    excludeTools = [
      "git"
      "jq"
      "ripgrep"
    ];

    instances.default = {
      enable = true;
      package = pkgs.openclaw;
    };
  };
}
