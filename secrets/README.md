# Secrets

このディレクトリには `sops-nix` で復号して配置する秘密情報を置く。

## 使い方

1. `age-keygen -o ~/.config/sops/age/keys.txt` で復号用の age 鍵を作る
2. `age-keygen -y ~/.config/sops/age/keys.txt` で公開鍵を取得する
3. リポジトリ直下の `.sops.yaml` の `AGE-RECIPIENT-PLACEHOLDER` を公開鍵に置き換える
4. `secrets/common.yaml` を作って `sops -e -i secrets/common.yaml` で暗号化する

## 例

```yaml
ssh:
  id_github_rsa: |
    -----BEGIN RSA PRIVATE KEY-----
    ...
    -----END RSA PRIVATE KEY-----
  id_rsa: |
    -----BEGIN RSA PRIVATE KEY-----
    ...
    -----END RSA PRIVATE KEY-----
  mirai-server: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----
  config: |
    Host github.com
      HostName github.com
      User git
      IdentityFile ~/.ssh/id_github_rsa
```

現在の Nix 設定では次を配置する:

- `ssh.config` -> `~/.ssh/config`
- `ssh.id_github_rsa` -> `~/.ssh/id_github_rsa`
- `ssh.id_rsa` -> `~/.ssh/id_rsa`
- `ssh.mirai-server` -> `~/.ssh/mirai-server`
