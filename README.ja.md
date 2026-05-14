# Agent Share Box

エージェント作業用の軽量ファイル共有です。

Markdown 記事、スクリーンショット、添付画像、生成物などを PC 間で
共有するために、`nginx + copyparty` の軽量 Docker コンテナを giobox 上に
デプロイします。トップは確認・閲覧用のミニマル UI、`/browse/` は
copyparty の標準 UI、root URL は WebDAV/curl でも使えます。

## デフォルト構成

- SSH 先: `giobox`
- systemd: `agent-share-box.service`
- URL: `http://<giobox-ip>:3923/`
- 共有データ: `/srv/agent-share-box`
- 容量: 50GB の loop-mounted ext4
- Runtime: systemd 管理の軽量 Docker コンテナ
- ブラウザ: `/` は閲覧UI、`/manage` は管理UI、`/recent` は最近のファイル
- 認証: LAN 用にデフォルト無効。必要なら `AGENT_SHARE_AUTH=1`
- 設定: `/etc/agent-share-box/agent-share-box.env`

本体 repo には設定テンプレートとデプロイスクリプトだけを置きます。
共有される 50GB の実データは Git 管理しません。

## デプロイ

```bash
./scripts/deploy-giobox.sh
```

デフォルトはローカルネットワーク向けの認証なしです。認証を有効にする
場合は次のように指定します。

```bash
AGENT_SHARE_AUTH=1 AGENT_SHARE_PASSWORD='your-password' ./scripts/deploy-giobox.sh
```

## 検証

```bash
AGENT_SHARE_URL=http://<giobox-ip>:3923 \
./scripts/smoke-test.sh
```

## macOS にマウント

```bash
./scripts/configure-macos-mount.sh
./scripts/mount-macos.sh
./scripts/status-macos.sh
```

helper は macOS の WebDAV マウントを直接使うため、デフォルトの LAN
モードではユーザー名・パスワード不要でマウントできます。

デフォルトでは次のリンクから使えます。

```text
~/agent-share-box -> /Volumes/<giobox-ip>
```

解除:

```bash
./scripts/unmount-macos.sh
```

## 運用確認

```bash
ssh giobox 'systemctl status agent-share-box --no-pager'
ssh giobox 'df -h /srv/agent-share-box'
ssh giobox 'journalctl -u agent-share-box -n 80 --no-pager'
```
