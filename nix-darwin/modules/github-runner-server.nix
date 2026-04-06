{ config, pkgs, ... }:
{
  services.github-runners.void2610-org = {
    enable = true;
    url = "https://github.com/void2610-org";
    tokenFile = config.sops.secrets.github_runner_void2610_org_token.path;
    name = "m1server";
    replace = true;

    extraLabels = [
      "macos"
      "apple-silicon"
      "m1server"
    ];

    extraPackages = with pkgs; [
      gh
      git
      nodejs_22
      yarn
    ];
  };
}
