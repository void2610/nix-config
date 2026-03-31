{
  programs.git = {
    enable = true;
    signing.format = "openpgp";
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
}
