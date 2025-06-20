# MinecraftBeSeverAutoUpdate
Automatic Update of Minecraft Bedrock Server for Linux

## Features
- 統合版マイクラサーバーのアップデート作業を自動化
- 複数サーバーセッション対応
- crontabによる完全自動化対応

## System Requirements
- Linux OS (Ubuntu推奨)
- Python 3.6以上
- Bash 4.0以上
- 必要なパッケージ: screen, curl, wget, unzip

## Installation

### 1. 必要パッケージのインストール
```bash
sudo apt update
sudo apt -y upgrade
sudo apt install screen curl wget unzip python3 python3-pip
```

### 2. Pythonパッケージのインストール
```bash
pip3 install selenium webdriver-manager
```

### 3. 実行権限の付与
```bash
cd /your_file_directory
chmod +x *.sh
```

## Configuration

### conf.txt設定
```bash
nano conf.txt
```

設定例:
```bash
# 前バージョン
old_ver='0.0.0.0'

# 最新バージョン
new_ver='1.21.84.1'

# ダウンロードURL (自動更新されます)
DOWNLOAD_URL=''

# セッション名 (複数指定可能、カンマ区切り)
SESSION_NAME='server, server2'

# サーバーディレクトリ
SERVER_DIR='/home/minecraft'

# サーバー更新後自動起動 (0→OFF, 1→ON)
AUTO_START_SERVER='1'
```

## Usage

### 手動実行
```bash
cd /your_file_directory
./has_update.sh
```

### crontabによる自動実行
```bash
crontab -e

# 例: 毎日午前3時50分に実行
50 3 * * * bash /your_file_directory/has_update.sh
```

## File Structure
```
MinecraftBeSeverAutoUpdate/
├── has_update.sh        # メインスクリプト (アップデート判定・実行)
├── mcs_start.sh         # サーバー起動スクリプト
├── mcs_stop.sh          # サーバー停止スクリプト
├── mcs_update.sh        # サーバー更新スクリプト
├── get_mc.py            # 最新バージョン・URL取得 (Python)
├── common_functions.sh  # 共通関数ライブラリ
├── conf.txt             # 設定ファイル
├── updatelog.txt        # アップデート履歴ログ
└── README.md            # このファイル
```

## How It Works

1. **バージョンチェック**: `get_mc.py`が公式サイトから最新バージョンとダウンロードURLを取得
2. **更新判定**: 現在のバージョンと最新バージョンを比較
3. **サーバー停止**: 更新が必要な場合、事前通知後にサーバーを停止
4. **ファイル更新**: 最新サーバーファイルをダウンロード・展開
5. **設定復元**: 既存の設定ファイルとワールドデータを新バージョンに移行
6. **サーバー起動**: 設定に応じて自動でサーバーを起動

## Logging
- 実行ログは `updatelog.txt` に記録されます
- エラー発生時には詳細な情報が出力されます
- バージョン更新履歴も自動で記録されます

## Safety Features
- 設定ファイルの自動バックアップ
- URL・バージョン情報の検証
- エラー時の自動ロールバック機能
- 段階的なサーバー停止（事前通知→1分待機→停止）

## Troubleshooting

### Python関連エラー
```bash
# Seleniumの再インストール
pip3 install --upgrade selenium webdriver-manager

# Chromeドライバーの手動更新
pip3 install --upgrade webdriver-manager
```

### 権限エラー
```bash
# 実行権限の確認・設定
ls -la *.sh
chmod +x *.sh
```

## Important Notes
⚠️ **必ずワールドデータや設定ファイルのバックアップを取ってから実行してください**

- ワールドデータの損失が発生する可能性があります
- 初回実行前にテスト環境での動作確認を推奨
- 重要なサーバーでは手動バックアップの併用を推奨

## License
このプロジェクトはMITライセンスの下で公開されています。

## Author
- tomo-ing
- Modified: 2025/6/19 - Python統合・共通関数化対応
