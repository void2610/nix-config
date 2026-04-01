{ config, lib, ... }:
let
  username = config.system.primaryUser;
  homeDir = config.users.users.${username}.home;
  secretsFile = ../../secrets/common.yaml;
  hasSecretsFile = builtins.pathExists secretsFile;
in
{
  sops = {
    age.keyFile = "${homeDir}/.config/sops/age/keys.txt";
    defaultSopsFormat = "yaml";
  } // lib.optionalAttrs hasSecretsFile {
    defaultSopsFile = secretsFile;
    secrets = {
      ssh_config = {
        path = "${homeDir}/.ssh/config";
        owner = username;
        mode = "600";
      };

      ssh_id_github_rsa = {
        path = "${homeDir}/.ssh/id_github_rsa";
        owner = username;
        mode = "600";
      };

      ssh_id_rsa = {
        path = "${homeDir}/.ssh/id_rsa";
        owner = username;
        mode = "600";
      };

      ssh_mirai_server = {
        path = "${homeDir}/.ssh/mirai-server";
        owner = username;
        mode = "600";
      };
    };
  };

  system.activationScripts.postActivation.text = lib.mkAfter ''
    /bin/mkdir -p ${homeDir}/.ssh
    /usr/sbin/chown ${username}:staff ${homeDir}/.ssh
    /bin/chmod 700 ${homeDir}/.ssh
    /bin/mkdir -p ${homeDir}/.config/sops/age
    /usr/sbin/chown ${username}:staff ${homeDir}/.config/sops/age
    /bin/chmod 700 ${homeDir}/.config/sops/age

    # sops-nix が SSH 秘密鍵の末尾改行を削除するため、シンボリックリンクを
    # 末尾改行付きの実ファイルに置き換える
    for key in id_github_rsa id_rsa mirai-server; do
      target="${homeDir}/.ssh/$key"
      if [ -L "$target" ]; then
        real=$(readlink "$target")
        /bin/unlink "$target"
        /bin/cat "$real" > "$target"
        /bin/echo "" >> "$target"
        /usr/sbin/chown ${username}:staff "$target"
        /bin/chmod 600 "$target"
      fi
    done
  '';
}
