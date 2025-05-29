# MinecraftBeSeverAutoUpdate
Automatic Update of Minecraft Bedrock Server for Linux
 
# Features
統合版マイクラサーバーのアップデート作業を自動化します。
crontabによる完全自動化も可。
 
# Usage

screenやcurlがインストールされていない場合
```
sudo apt update
sudo apt -y upgrade
sudo apt install screen
sudo apt install curl
```

config設定
```
nano conf.txt

---例
...
# セッション名
SESSION_NAME='bds01, bds02'

# サーバーディレクトリ
SERVER_DIR='/home/minecraft/server'

#サーバー更新後自動起動(0→OFF, 1→ON)
AUTO_START_SERVER='1
---
```

実行権限の付与
```
cd /your_file_directory
chmod +x has_update.sh  mcs_start.sh  mcs_stop.sh  mcs_update.sh
```
自動更新の実行
```
cd your_file_directory
bash has_update.sh
```

crontabによる完全自動化
```
crontab -e

---例
...
50 3 * * * bash /your_file_directory/has_update.sh
---
```

# Note
必ずワールドデータや設定ファイル等のバックアップを取ってから実行するようにしてください。
ワールドデータを新バージョンにコピーする際データの損失等が発生する可能性があります。
