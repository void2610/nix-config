# Secrets

このディレクトリには `sops-nix` で復号して配置する秘密情報を置く。

## 使い方

1. `age-keygen -o ~/.config/sops/age/keys.txt` で復号用の age 鍵を作る
2. `age-keygen -y ~/.config/sops/age/keys.txt` で公開鍵を取得する
3. リポジトリ直下の `.sops.yaml` の `AGE-RECIPIENT-PLACEHOLDER` を公開鍵に置き換える
4. `secrets/common.yaml` を作って `sops -e -i secrets/common.yaml` で暗号化する

## 例

```yaml
ssh_config: |
  Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github_rsa
ssh_id_github_rsa: |
  -----BEGIN RSA PRIVATE KEY-----
  ...
  -----END RSA PRIVATE KEY-----
ssh_id_rsa: |
  -----BEGIN RSA PRIVATE KEY-----
  ...
  -----END RSA PRIVATE KEY-----
ssh_mirai_server: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

現在の Nix 設定では次を配置する:

- `ssh.config` -> `~/.ssh/config`
- `ssh.id_github_rsa` -> `~/.ssh/id_github_rsa`
- `ssh.id_rsa` -> `~/.ssh/id_rsa`
- `ssh.mirai-server` -> `~/.ssh/mirai-server`

server profile では追加で次も使う:

- `github_runner_void2610_org_token` -> GitHub Actions self-hosted runner の registration token

`github_runner_void2610_org_token` は GitHub 組織 `void2610-org` の runner 登録用トークンを入れる。
このトークンは有効期限が短いため、runner を再登録するときは GitHub 側で新しい値を発行して `sops` で更新する。

現在の runner 設定は永続運用を前提にしているため、通常の `darwin-rebuild switch` では再登録しない。
runner 名の変更や GitHub 側で登録を削除したあとに再登録が必要になったときだけ、この token を更新すればよい。

game / server profile では追加で次も使う:

- `apple_development_p12` -> Strix などの署名に使う Apple Development 証明書と秘密鍵 (PKCS#12 を base64 にしたもの)
- `apple_development_password` -> 上の PKCS#12 と、取り込み先の専用キーチェーン `~/Library/Keychains/apple-development.keychain-db` のパスワード

無料 Apple ID は有効な開発用証明書を 1 枚しか持てず、Mac ごとに Xcode で作ると互いに失効させ合い、失効した証明書で署名したアプリは起動しなくなる。
そのため 1 枚を sops で配り、`apple-development-signing.nix` がログイン時に専用キーチェーンへ取り込んで解錠する。

証明書が失効・期限切れになって作り直したときは、作った Mac から秘密鍵ごと PKCS#12 で書き出して両方の値を更新し、両方のホストで `darwin-rebuild switch` する。

```bash
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
printf '"%s"' "$(base64 -i identity.p12 | tr -d '\n')" | sops set --value-stdin secrets/common.yaml '["apple_development_p12"]'
printf '"%s"' "<PKCS#12 のパスワード>" | sops set --value-stdin secrets/common.yaml '["apple_development_password"]'
```
