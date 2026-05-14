# Agent Share Box

エージェント作業用の軽量ファイル共有です。

Markdown 記事、スクリーンショット、添付画像、生成物などを PC 間で
共有するために、`copyparty` を systemd サービスとして giobox 上に
デプロイします。ブラウザ UI と WebDAV/curl の両方で使えます。

## デフォルト構成

- SSH 先: `giobox`
- systemd: `agent-share-box.service`
- URL: `http://<giobox-ip>:3923/`
- 共有データ: `/srv/agent-share-box`
- 容量: 50GB の loop-mounted ext4
- 認証情報: `/etc/agent-share-box/agent-share-box.env`

本体 repo には設定テンプレートとデプロイスクリプトだけを置きます。
共有される 50GB の実データは Git 管理しません。

## デプロイ

```bash
./scripts/deploy-giobox.sh
```

パスワードは自動生成され、標準出力に表示されます。再デプロイ時に固定
したい場合は次のように指定します。

```bash
AGENT_SHARE_PASSWORD='your-password' ./scripts/deploy-giobox.sh
```

## 検証

```bash
AGENT_SHARE_URL=http://<giobox-ip>:3923 \
AGENT_SHARE_USERNAME=agent \
AGENT_SHARE_PASSWORD='<password>' \
./scripts/smoke-test.sh
```

## macOS にマウント

```bash
AGENT_SHARE_PASSWORD='<password>' ./scripts/configure-macos-mount.sh
./scripts/mount-macos.sh
./scripts/status-macos.sh
```

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
