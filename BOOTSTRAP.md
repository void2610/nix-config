# Bootstrap

## 1. age 秘密鍵を戻す

パスワードマネージャーに保存した `nix-config sops age key` を `~/.config/sops/age/keys.txt` に復元する。

```bash
mkdir -p ~/.config/sops/age
chmod 700 ~/.config/sops/age
$EDITOR ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

## 2. Nix を入れる

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
```

Nix インストール後、新しいシェルを開く。

## 3. リポジトリを clone する

```bash
git clone https://github.com/void2610/.nix-config.git ~/.nix-config
git clone https://github.com/void2610/dotfiles.git ~/dotfiles
```

## 4. nix-darwin を適用する

```bash
cd ~/.nix-config
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#work
```

これで `sops-nix` により SSH secrets が `~/.ssh` に復元される。
別ホストを使う場合は `.#game` / `.#work` / `.#server` に切り替える。

## 5. dotfiles をリンクする

```bash
cd ~/dotfiles
./install.sh
```

## 6. 通常の rebuild を実行する

```bash
cd ~/.nix-config
sudo darwin-rebuild switch --flake .#work
```

## 7. 動作確認

```bash
which brew
which mas
which node
which dotnet
git config user.email
ls -la ~/.ssh
```

## 8. 手動復元

- `~/dotfiles/MANUAL_APPS.md` のアプリを入れる
- Unity Editor `6000.3.10f1` と必要モジュールを入れる
- 各アプリにログインする

## 補足

- 最初に必要なのは age の秘密鍵だけ
- SSH 鍵自体は `secrets/common.yaml` から復元される
- `secrets/common.yaml` を復号できなくなるので、`~/.config/sops/age/keys.txt` は必ず別保管する
