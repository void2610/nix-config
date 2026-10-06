{ pkgs, ... }:
{
  programs.gh = {
    enable = true;

    settings = {
      git_protocol = "https";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
      };
    };

    # gh は PATH 上の gh-* ではなく自身の拡張ディレクトリだけを見るため home.packages では認識されない
    extensions = [
      pkgs.gh-stack
      pkgs.gh-dash
    ];
  };
}
