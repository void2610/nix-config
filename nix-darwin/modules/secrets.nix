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

  system.activationScripts.ensureSecretDirs.text = lib.mkAfter ''
    /usr/bin/install -d -m 700 -o ${username} -g staff ${homeDir}/.ssh
    /usr/bin/install -d -m 700 -o ${username} -g staff ${homeDir}/.config/sops/age
  '';
}
