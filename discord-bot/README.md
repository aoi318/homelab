# Discord Bot

`game01`（VMID 102）の起動、正常停止、状態確認を行うDiscord Botです。

## コマンド

- `!status`
- `!start`
- `!stop`

`!start`と`!stop`は、PVEへの要求受付ではなく、`game01`が実際に起動・停止したことを確認してから完了メッセージを返す。確認は最大5分待機する。

## 配置

`infra01`上で次を実行する。

```bash
git clone <repository-url> /opt/homelab
cd /opt/homelab/discord-bot
cp .env.example .env
chmod 600 .env
# .envへDiscordトークンとPVE APIトークンを設定する
docker compose up -d --build
```

Discord Developer Portalで、Botへ**Message Content Intent**を有効化する。トークンはGitへ登録しない。

Botが参加しているDiscordサーバーのメンバーは、全員がコマンドを実行できる。

PVE APIトークンには、`/vms/102`に対する`VM.Audit`と`VM.PowerMgmt`だけを付与する。

## `.env` の作成（PowerShell）

次のコマンドは`infra01`上の`/opt/homelab/discord-bot/.env`を作成してBotを起動する。`DISCORD_TOKEN`、PVE APIトークンのシークレット、SSH秘密鍵はGitへ登録しない。

```powershell
$discordTokenSecure = Read-Host -AsSecureString "Discord Bot token"
$discordToken = [System.Net.NetworkCredential]::new("", $discordTokenSecure).Password

@"
DISCORD_TOKEN=$discordToken
PVE_TOKEN_ID=gamebot@pve!discordbot
PVE_TOKEN_SECRET=REPLACE_WITH_PVE_TOKEN_SECRET
PVE_API_URL=https://PVE_HOST:8006/api2/json
PVE_VERIFY_SSL=false
PVE_NODE=pve01
PVE_VM_ID=102
"@ | ssh -i "$env:USERPROFILE\.ssh\homelab_bastion" ADMIN_USER@INFRA01_HOST "sudo tee /opt/homelab/discord-bot/.env > /dev/null; sudo chown root:root /opt/homelab/discord-bot/.env; sudo chmod 600 /opt/homelab/discord-bot/.env; cd /opt/homelab/discord-bot; sudo docker compose up -d --build; sudo docker compose ps"
```
