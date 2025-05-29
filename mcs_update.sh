#!/bin/bash

# スクリプト自身のディレクトリを取得
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

CONF_FILE=${SCRIPT_DIR}/conf.txt

# conf.txt ファイルの存在確認
if [ ! -f "$CONF_FILE" ]; then
  echo "エラー: 設定ファイル '$CONF_FILE' が見つかりません。" >&2
  exit 1
fi

# 設定ファイルから変数取得
# '^キー名=' で行を特定し、'='以降を取得、シングルクォートを除去後、数字とドット以外を削除
old_ver=$(grep "^old_ver=" "$CONF_FILE" | cut -d'=' -f2- | sed "s/^'//;s/'$//" | sed 's/[^0-9.]//g')
new_ver=$(grep "^new_ver=" "$CONF_FILE" | cut -d'=' -f2- | sed "s/^'//;s/'$//" | sed 's/[^0-9.]//g')

# SERVER_DIR の取得 (例: SERVER_DIR='/home/minecraft')
# '^キー名=' で行を特定し、'='以降を取得、シングルクォートを除去
SERVER_DIR=$(grep "^SERVER_DIR=" "$CONF_FILE" | cut -d'=' -f2- | sed "s/^'//;s/'$//")

# session_list の取得 (例: SESSION_NAME='s1, s2')
# '^キー名=' で行を特定し、'='以降を取得、シングルクォートを除去 
session_list=$(grep "^SESSION_NAME=" "$CONF_FILE" | cut -d'=' -f2- | sed "s/^'//;s/'$//")

if [ -z "$session_list" ]; then
  echo "エラー: '$CONF_FILE' に SESSION_NAME の設定が見つからないか、値が空です。" >&2
  exit 1
fi

# カンマを区切り文字としてセッション名を一つずつ処理
#    - `IFS=','` で内部フィールドセパレータをカンマに設定。
#    - `read -r -a sessions_array <<< "$raw_session_list"` でカンマ区切りの文字列を配列に格納。
#      (`-r` はバックスラッシュを解釈しない、`-a array` で配列に読み込む)
IFS=',' read -r -a sessions_array <<< "$session_list"


DOWNLOAD_URL=$(curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -s -L -A "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; BEDROCK-UPDATER)" https://minecraft.net/en-us/download/server/bedrock/ |  grep -o 'https.*/bin-linux/.*.zip')

start_date=`date "+%Y/%m/%d/%H:%M:%S"`
start_time=`date +%s`

echo -n ${old_ver} - ${new_ver}, ${start_date} >> /home/minecraft/command/updatelog.txt

# serverのディレクトリ
SERVER_DIR1=/home/minecraft/server
SERVER_DIR2=/home/minecraft/server2

# 現在のbedrock_serverのディレクトリ
# old_verは設定ファイル内
SERVER_DIR01=/home/minecraft/server/bedrock_server${old_ver}
SERVER_DIR02=/home/minecraft/server2/bedrock_server${old_ver}

# 新しいbedrock_serverのディレクトリ
# verは設定ファイル内
NEW_SERVER_DIR01=/home/minecraft/server/bedrock_server${new_ver}
NEW_SERVER_DIR02=/home/minecraft/server2/bedrock_server${new_ver}


# サーバーの停止
screen -S ${SESSION_NAME01} -X stuff '\nstop\n'
screen -S ${SESSION_NAME02} -X stuff '\nstop\n'
sleep 5
screen -r ${SESSION_NAME01}
screen -r ${SESSION_NAME02}
sleep 5

# ワールドデータのバックアップ
#cd /home/minecraft/server/bedrock_server${old_ver}/
#tar cvf /home/share/mcsbackup/backup-${old_ver}-`date +%Y%m%d`.tar ./worlds
#gzip /home/share/mcsbackup/backup-${old_ver}-`date +%Y%m%d`.tar
#sleep 60
#cd /home/minecraft/server2/bedrock_server${old_ver}/
#tar cvf /home/share/mcsbackup2/backup-${old_ver}-`date +%Y%m%d`.tar ./worlds
#gzip /home/share/mcsbackup2/backup-${old_ver}-`date +%Y%m%d`.tar
#sleep 60

# 新しいサーバーのディレクトりの作成
cd ${SERVER_DIR1}
mkdir bedrock_server${new_ver}

# サーバーのダウンロード
cd ${NEW_SERVER_DIR01}
curl -L -O https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${new_ver}.zip
wget -U -O "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; BEDROCK-UPDATER)" $DOWNLOAD_URL
sleep 1

# ファイルの解凍
unzip bedrock-server-${new_ver}.zip
sleep 5

# サーバーの一時起動
# SESSION_NAMEは設定ファイル内
LD_LIBRARY_PATH=. screen -dmS ${SESSION_NAME01} ./bedrock_server > ./bedrock_server01.log &
sleep 10
screen -S ${SESSION_NAME01} -X stuff '\nstop\n'
sleep 5

# 新ワールドデータの削除
rm -r worlds
sleep 5

# サーバー2へのファイルコピー
cp -r ${NEW_SERVER_DIR01} ${SERVER_DIR2}
sleep 5

# ワールドデータのコピー
cp -r ${SERVER_DIR01}/worlds ${NEW_SERVER_DIR01}
sleep 30
cp -r ${SERVER_DIR02}/worlds ${NEW_SERVER_DIR02}
sleep 30

# サーバーの起動
cd ${NEW_SERVER_DIR01}
cp -pf /home/minecraft/server.properties server.properties
cp -pf /home/minecraft/permissions.json permissions.json
cp -pf /home/minecraft/allowlist.json allowlist.json
LD_LIBRARY_PATH=. screen -dmS ${SESSION_NAME01} ./bedrock_server > ./bedrock_server01.log &

sleep 30

cd ${NEW_SERVER_DIR02}
cp -pf /home/minecraft/server.properties2 server.properties
cp -pf /home/minecraft/permissions.json permissions.json
LD_LIBRARY_PATH=. screen -dmS ${SESSION_NAME02} ./bedrock_server > ./bedrock_server02.log &

sleep 30

# 前サーバーの削除
rm -r ${SERVER_DIR01}
sleep 10
rm -r ${SERVER_DIR02}
sleep 10

# サーバーアップデート完了ログ出力
end_date=`date "+%Y/%m/%d/%H:%M:%S"`
end_time=`date +%s`

echo , ${end_date}, $(($end_time - $start_time)) >> /home/minecraft/command/updatelog.txt
