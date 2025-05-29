#!/bin/bash

#----------------------------------------------------
#   Program name : mcs_update.sh
#   Date of program : 2025/5/29
#   Author : tomo-ing
#----------------------------------------------------

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
IFS=',' read -r -a sessions_array_with_spaces <<< "$session_list"

# 次に、各要素から前後の空白を除去した新しい配列を作成
sessions_array=()
for item in "${sessions_array_with_spaces[@]}"; do
  # Bashのパラメータ展開を使用して前後の空白を除去
  # まず先頭の空白を除去
  item_no_leading_space="${item#"${item%%[![:space:]]*}"}"
  # 次に末尾の空白を除去
  item_trimmed="${item_no_leading_space%"${item_no_leading_space##*[![:space:]]}"}"
  sessions_array+=("$item_trimmed")
done


DOWNLOAD_URL=$(curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -s -L -A "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; BEDROCK-UPDATER)" https://minecraft.net/en-us/download/server/bedrock/ |  grep -o 'https.*/bin-linux/.*.zip')

start_date=`date "+%Y/%m/%d/%H:%M:%S"`
start_time=`date +%s`

echo -n ${old_ver} - ${new_ver}, ${start_date} >> ${SCRIPT_DIR}/updatelog.txt

# 配列の要素数をチェック (オプション)
array_length="${#sessions_array[@]}"

if [ "$array_length" -eq 1 ]; then
  first_session="${sessions_array[0]}"
  remaining_sessions=() # 空の配列
else
  # 最初の1つの要素を取得
  first_session="${sessions_array[0]}"

  # それ以外の要素 (2番目以降のすべての要素) を新しい配列として取得
  # `${sessions_array[@]:1}` は、インデックス1 (2番目の要素) から始まるすべての要素を展開します。
  # それを `()` で囲んで新しい配列 remaining_sessions に格納します。
  remaining_sessions=("${sessions_array[@]:1}")
fi

# serverのディレクトリ
FIRST_SERVER_DIR=${SERVER_DIR}/${first_session}

# 現在のbedrock_serverのディレクトリ
# old_verは設定ファイル内
OLD_FIRST_SERVER_DIR=${FIRST_SERVER_DIR}/bedrock_server${old_ver}

# 新しいbedrock_serverのディレクトリ
# verは設定ファイル内
NEW_FIRST_SERVER_DIR=${FIRST_SERVER_DIR}/bedrock_server${new_ver}

 # 指定したフォルダが存在しない場合に作成。
mkdir -p "$NEW_FIRST_SERVER_DIR"

# サーバーのダウンロード
cd ${NEW_FIRST_SERVER_DIR}
curl -L -O https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${new_ver}.zip
wget -U -O "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; BEDROCK-UPDATER)" $DOWNLOAD_URL
sleep 1

# ファイルの解凍
unzip bedrock-server-${new_ver}.zip
sleep 5

# サーバーの一時起動
# SESSION_NAMEは設定ファイル内
LD_LIBRARY_PATH=. screen -dmS ${first_session} ./bedrock_server > ./${first_session}.log &
sleep 10
screen -S ${first_session} -X stuff '\nstop\n'
sleep 5

# 新ワールドデータの削除
rm -r worlds
sleep 5

if [ "${#remaining_sessions[@]}" -gt 0 ]; then
  for session in "${remaining_sessions[@]}"; do
    # serverのディレクトリ
    SESSION_SERVER_DIR=${SERVER_DIR}/${session}
    # 指定したフォルダが存在しない場合に作成。
    mkdir -p "$SESSION_SERVER_DIR"
    # サーバー2以降へのファイルコピー
    cp -r ${NEW_FIRST_SERVER_DIR} ${SESSION_SERVER_DIR}
    sleep 5
  done
fi

# ワールドファイルコピー
for session in "${sessions_array[@]}"; do
    # serverのディレクトリ
    SESSION_SERVER_DIR=${SERVER_DIR}/${session}
    OLD_SESSION_SERVER_DIR=${SESSION_SERVER_DIR}/bedrock_server${old_ver}
    NEW_SESSION_SERVER_DIR=${SESSION_SERVER_DIR}/bedrock_server${new_ver}
    # ワールドファイルコピー
    cp -r ${OLD_SESSION_SERVER_DIR}/worlds ${NEW_SESSION_SERVER_DIR}
    sleep 10
done

# 前サーバーの削除
for session in "${sessions_array[@]}"; do
    # serverのディレクトリ
    SESSION_SERVER_DIR=${SERVER_DIR}/${session}
    OLD_SESSION_SERVER_DIR=${SESSION_SERVER_DIR}/bedrock_server${old_ver}
    # 前サーバーの削除
    if [ -d "$OLD_SESSION_SERVER_DIR" ]; then
      rm -r ${OLD_SESSION_SERVER_DIR}
      sleep 10
    fi
done

# サーバーアップデート完了ログ出力
end_date=`date "+%Y/%m/%d/%H:%M:%S"`
end_time=`date +%s`

echo , ${end_date}, $(($end_time - $start_time)) >> ${SCRIPT_DIR}/updatelog.txt
