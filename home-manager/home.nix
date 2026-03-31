{ pkgs, ... }:
let
  homeDir = "/Users/shuya";
in
{
  # ホームディレクトリとユーザー名
  home.username = "shuya";
  home.homeDirectory = homeDir;

  # home-manager のバージョン
  home.stateVersion = "24.11";

  # --- インストールするパッケージ（将来 Homebrew から移行するもの） ---
  home.packages = with pkgs; [
    dotnet-sdk # Unity プロジェクトのフォーマットチェックで使用
  ];

  home.sessionPath = [
    "/Applications/platform-tools"
    "${homeDir}/Documents"
    "${homeDir}/.local/bin"
    "${homeDir}/.yarn/bin"
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk}/share/dotnet";
  };

  programs.git = {
    enable = true;
    ignores = [
      "**/.claude/settings.local.json"
      ".DS_Store"
    ];
    settings = {
      user = {
        name = "void2610";
        email = "contact@void2610.dev";
      };
      alias = {
        unstage = "reset HEAD";
      };
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
    };
  };

  # home-manager 自身による管理を有効化
  programs.home-manager.enable = true;
}
